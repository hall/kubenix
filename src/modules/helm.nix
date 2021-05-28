# helm defines kubenix module with options for using helm charts
# with kubenix

{ config, lib, pkgs, helm, ... }:

with lib;
let
  cfg = config.kubernetes.helm;

  globalConfig = config;

  recursiveAttrs = mkOptionType {
    name = "recursive-attrs";
    description = "recursive attribute set";
    check = isAttrs;
    merge = loc: foldl' (res: def: recursiveUpdate res def.value) { };
  };

  parseApiVersion = apiVersion:
    let
      splitted = splitString "/" apiVersion;
    in
    {
      group = if length splitted == 1 then "core" else head splitted;
      version = last splitted;
    };

in
{
  imports = [ ./k8s.nix ];

  options.kubernetes.helm = {
    instances = mkOption {
      description = "Attribute set of helm instances";
      type = types.attrsOf (types.submodule ({ config, name, ... }: {
        options = {
          name = mkOption {
            description = "Helm release name";
            type = types.str;
            default = name;
          };

          chart = mkOption {
            description = "Helm chart to use";
            type = types.package;
          };

          namespace = mkOption {
            description = "Namespace to install helm chart to";
            type = types.nullOr types.str;
            default = null;
          };

          values = mkOption {
            description = "Values to pass to chart";
            type = recursiveAttrs;
            default = { };
          };

          kubeVersion = mkOption {
            description = "Kubernetes version to build chart for";
            type = types.str;
            default = globalConfig.kubernetes.version;
          };

          overrides = mkOption {
            description = "Overrides to apply to all chart resources";
            type = types.listOf types.unspecified;
            default = [ ];
          };

          overrideNamespace = mkOption {
            description = "Whether to apply namespace override";
            type = types.bool;
            default = true;
          };

          objects = mkOption {
            description = "Generated kubernetes objects";
            type = types.listOf types.attrs;
            default = [ ];
          };
        };

        config.overrides = mkIf (config.overrideNamespace && config.namespace != null) [{
          metadata.namespace = config.namespace;
        }];

        config.objects = importJSON (helm.chart2json {
          inherit (config) chart name namespace values kubeVersion;
        });
      }));
      default = { };
    };
  };

  config = {
    # expose helm helper methods as module argument
    _module.args.helm = import ../lib/helm { inherit pkgs; };

    kubernetes.api.resources = mkMerge (flatten (mapAttrsToList
      (_: instance:
        map
          (object:
            let
              apiVersion = parseApiVersion object.apiVersion;
              name = object.metadata.name;
            in
            {
              "${apiVersion.group}"."${apiVersion.version}".${object.kind}."${name}" = mkMerge ([
                object
              ] ++ instance.overrides);
            })
          instance.objects
      )
      cfg.instances));
  };
}

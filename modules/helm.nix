# helm defines kubenix module with options for using helm charts
# with kubenix
{ config, lib, pkgs, helm, ... }:
with lib; let
  cfg = config.kubernetes.helm;

  globalConfig = config;

  recursiveAttrs = mkOptionType {
    name = "recursive-attrs";
    description = "recursive attribute set";
    check = isAttrs;
    merge = _loc: foldl' (res: def: recursiveUpdate res def.value) { };
  };

  parseApiVersion = apiVersion:
    let
      splitted = splitString "/" apiVersion;
    in
    {
      group =
        if length splitted == 1
        then "core"
        else head splitted;
      version = last splitted;
    };
in
{
  imports = [ ./k8s.nix ];

  options.kubernetes.helm = {
    releases = mkOption {
      description = "Attribute set of helm releases";
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

          includeCRDs = mkOption {
            description = ''
              Whether to include CRDs.

              Warning: Always including CRDs here is dangerous and can break CRs in your cluster as CRDs may be updated unintentionally.
              An interactive `helm install` NEVER updates CRDs, only installs them when they are not existing.
              See https://github.com/helm/community/blob/aa8e13054d91ee69857b13149a9652be09133a61/hips/hip-0011.md

              Only set this to true if you know what you are doing and are manually checking the included CRDs for breaking changes whenever updating the Helm chart.
            '';
            type = types.bool;
            default = false;
          };

          noHooks = mkOption {
            description = ''
              Wether to include Helm hooks.

              Without this all hooks run immediately on apply since we are bypassing the Helm CLI.
              However, some charts only have minor validation hooks (e.g., upgrade version skew validation) and are safe to ignore.
            '';
            type = types.bool;
            default = false;
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
          inherit (config) chart name namespace values kubeVersion includeCRDs noHooks;
        });
      }));
      default = { };
    };
  };

  config = {
    # expose helm helper methods as module argument
    _module.args.helm = import ../lib/helm { inherit pkgs; };

    kubernetes.api.resources = mkMerge (flatten (mapAttrsToList
      (_: release: map
        (object:
          let
            apiVersion = parseApiVersion object.apiVersion;
            inherit (object.metadata) name;
          in
          {
            "${apiVersion.group}"."${apiVersion.version}".${object.kind}."${name}" = mkMerge ([
              object
            ]
            ++ release.overrides);
          })
        release.objects
      )
      cfg.releases));
  };
}

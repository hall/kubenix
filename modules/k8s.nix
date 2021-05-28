# K8S module defines kubernetes definitions for kubenix

{ options, config, lib, pkgs, k8s, ... }:

with lib;
let
  cfg = config.kubernetes;

  gvkKeyFn = type: "${type.group}/${type.version}/${type.kind}";

  getDefaults = resource: group: version: kind:
    catAttrs "default" (filter
      (default:
        (resource == null || default.resource == null || default.resource == resource) &&
        (default.group == null || default.group == group) &&
        (default.version == null || default.version == version) &&
        (default.kind == null || default.kind == kind)
      )
      cfg.api.defaults);

  moduleToAttrs = value:
    if isAttrs value
    then mapAttrs (n: v: moduleToAttrs v) (filterAttrs (n: v: v != null && !(hasPrefix "_" n)) value)

    else if isList value
    then map (v: moduleToAttrs v) value

    else value;

  apiOptions = { config, ... }: {
    options = {
      definitions = mkOption {
        description = "Attribute set of kubernetes definitions";
      };

      defaults = mkOption {
        description = "Kubernetes defaults to apply to resources";
        type = types.listOf (types.submodule ({ config, ... }: {
          options = {
            group = mkOption {
              description = "Group to apply default to (all by default)";
              type = types.nullOr types.str;
              default = null;
            };

            version = mkOption {
              description = "Version to apply default to (all by default)";
              type = types.nullOr types.str;
              default = null;
            };

            kind = mkOption {
              description = "Kind to apply default to (all by default)";
              type = types.nullOr types.str;
              default = null;
            };

            resource = mkOption {
              description = "Resource to apply default to (all by default)";
              type = types.nullOr types.str;
              default = null;
            };

            propagate = mkOption {
              description = "Whether to propagate defaults";
              type = types.bool;
              default = false;
            };

            default = mkOption {
              description = "Default to apply";
              type = types.unspecified;
              default = { };
            };
          };
        }));
        default = [ ];
        apply = unique;
      };

      types = mkOption {
        description = "List of registered kubernetes types";
        type = coerceListOfSubmodulesToAttrs
          {
            options = {
              group = mkOption {
                description = "Resource type group";
                type = types.str;
              };

              version = mkOption {
                description = "Resoruce type version";
                type = types.str;
              };

              kind = mkOption {
                description = "Resource type kind";
                type = types.str;
              };

              name = mkOption {
                description = "Resource type name";
                type = types.nullOr types.str;
              };

              attrName = mkOption {
                description = "Name of the nixified attribute";
                type = types.str;
              };
            };
          }
          gvkKeyFn;
        default = { };
      };
    };

    config = {
      # apply aliased option
      resources = mkAliasDefinitions options.kubernetes.resources;
    };
  };

  indexOf = lst: value:
    head (filter (v: v != -1) (imap0 (i: v: if v == value then i else -1) lst));

  compareVersions = ver1: ver2:
    let
      getVersion = v: substring 1 10 v;
      splittedVer1 = builtins.splitVersion (getVersion ver1);
      splittedVer2 = builtins.splitVersion (getVersion ver2);

      v1 = if length splittedVer1 == 1 then "${getVersion ver1}prod" else getVersion ver1;
      v2 = if length splittedVer2 == 1 then "${getVersion ver2}prod" else getVersion ver2;
    in
    builtins.compareVersions v1 v2;

  customResourceTypesByAttrName = zipAttrs (mapAttrsToList
    (_: resourceType: {
      ${resourceType.attrName} = resourceType;
    })
    cfg.customTypes);

  customResourceTypesByAttrNameSortByVersion = mapAttrs
    (_: resourceTypes:
      reverseList (sort
        (r1: r2:
          compareVersions r1.version r2.version > 0
        )
        resourceTypes)
    )
    customResourceTypesByAttrName;

  latestCustomResourceTypes =
    mapAttrsToList (_: resources: last resources) customResourceTypesByAttrNameSortByVersion;

  customResourceModuleForType = config: ct: { name, ... }: {
    imports = getDefaults ct.name ct.group ct.version ct.kind;
    options = {
      apiVersion = mkOption {
        description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/api-conventions.md#resources";
        type = types.nullOr types.str;
      };

      kind = mkOption {
        description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/api-conventions.md#types-kinds";
        type = types.nullOr types.str;
      };

      metadata = mkOption {
        description = "Standard object metadata; More info: https://git.k8s.io/community/contributors/devel/api-conventions.md#metadata.";
        type = types.nullOr (types.submodule config.definitions."io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
      };

      spec = mkOption {
        description = "Module spec";
        type = types.either types.attrs (types.submodule ct.module);
        default = { };
      };
    };

    config = {
      apiVersion = mkOptionDefault "${ct.group}/${ct.version}";
      kind = mkOptionDefault ct.kind;
      metadata.name = mkDefault name;
    };
  };

  customResourceOptions = (mapAttrsToList
    (_: ct: { config, ... }:
      let
        module = customResourceModuleForType config ct;
      in
      {
        options.resources.${ct.group}.${ct.version}.${ct.kind} = mkOption {
          description = ct.description;
          type = types.attrsOf (types.submodule module);
          default = { };
        };
      })
    cfg.customTypes) ++ (map
    (ct: { options, config, ... }:
      let
        module = customResourceModuleForType config ct;
      in
      {
        options.resources.${ct.attrName} = mkOption {
          description = ct.description;
          type = types.attrsOf (types.submodule module);
          default = { };
        };

        config.resources.${ct.group}.${ct.version}.${ct.kind} =
          mkAliasDefinitions options.resources.${ct.attrName};
      })
    latestCustomResourceTypes);

in
{
  imports = [ ./base.nix ];

  options.kubernetes = {
    version = mkOption {
      description = "Kubernetes version to use";
      type = types.enum [ "1.19" "1.20" "1.21" ];
      default = "1.21";
    };

    namespace = mkOption {
      description = "Default namespace where to deploy kubernetes resources";
      type = types.nullOr types.str;
      default = null;
    };

    resourceOrder = mkOption {
      description = "Preffered resource order";
      type = types.listOf types.str;
      default = [
        "CustomResourceDefinition"
        "Namespace"
      ];
    };

    api = mkOption {
      type = types.submodule {
        imports = [
          (./generated + ''/v'' + cfg.version + ".nix")
          apiOptions
        ] ++ customResourceOptions;
      };
      default = { };
    };

    imports = mkOption {
      type = types.listOf (types.either types.package types.path);
      description = "List of resources to import";
      default = [ ];
    };

    resources = mkOption {
      description = "Alias for `config.kubernetes.api.resources` options";
      default = { };
      type = types.attrsOf types.attrs;
    };

    customTypes = mkOption {
      description = "List of custom resource types to make API for";
      type = coerceListOfSubmodulesToAttrs
        {
          options = {
            group = mkOption {
              description = "Custom type group";
              type = types.str;
            };

            version = mkOption {
              description = "Custom type version";
              type = types.str;
            };

            kind = mkOption {
              description = "Custom type kind";
              type = types.str;
            };

            name = mkOption {
              description = "Custom type resource name";
              type = types.nullOr types.str;
              default = null;
            };

            attrName = mkOption {
              description = "Name of the nixified attribute";
              type = types.str;
            };

            description = mkOption {
              description = "Custom type description";
              type = types.str;
              default = "";
            };

            module = mkOption {
              description = "Custom type module";
              type = types.unspecified;
              default = { };
            };
          };
        }
        gvkKeyFn;
      default = { };
    };

    objects = mkOption {
      description = "List of generated kubernetes objects";
      type = types.listOf types.attrs;
      apply = items: sort
        (r1: r2:
          if elem r1.kind cfg.resourceOrder && elem r2.kind cfg.resourceOrder
          then indexOf cfg.resourceOrder r1.kind < indexOf cfg.resourceOrder r2.kind
          else if elem r1.kind cfg.resourceOrder then true else false
        )
        (unique items);
      default = [ ];
    };

    generated = mkOption {
      description = "Generated kubernetes list object";
      type = types.attrs;
    };

    result = mkOption {
      description = "Generated kubernetes JSON file";
      type = types.package;
    };

    resultYAML = mkOption {
      description = "Genrated kubernetes YAML file";
      type = types.package;
    };
  };

  config = {
    # features that module is defining
    _m.features = [ "k8s" ];

    # module propagation options
    _m.propagate = [{
      features = [ "k8s" ];
      module = { config, ... }: {
        # propagate kubernetes version and namespace
        kubernetes.version = mkDefault cfg.version;
        kubernetes.namespace = mkDefault cfg.namespace;
      };
    }
      {
        features = [ "k8s" "submodule" ];
        module = { config, ... }: {
          # set module defaults
          kubernetes.api.defaults = (
            # propagate defaults if default propagation is enabled
            (filter (default: default.propagate) cfg.api.defaults) ++

            [
              # set module name and version for all kuberentes resources
              {
                default.metadata.labels = {
                  "kubenix/module-name" = config.submodule.name;
                  "kubenix/module-version" = config.submodule.version;
                };
              }
            ]
          );
        };
      }];

    # expose k8s helper methods as module argument
    _module.args.k8s = import ../lib/k8s { inherit lib; };

    kubernetes.api = mkMerge ([{
      # register custom types
      types = mapAttrsToList
        (_: cr: {
          inherit (cr) name group version kind attrName;
        })
        cfg.customTypes;

      defaults = [{
        default = {
          # set default kubernetes namespace to all resources
          metadata.namespace = mkIf (config.kubernetes.namespace != null)
            (mkDefault config.kubernetes.namespace);

          # set project name to all resources
          metadata.annotations = {
            "kubenix/project-name" = config.kubenix.project;
            "kubenix/k8s-version" = cfg.version;
          };
        };
      }];
    }] ++

    # import of yaml files
    (map
      (i:
        let
          # load yaml file
          object = loadYAML i;
          groupVersion = splitString "/" object.apiVersion;
          name = object.metadata.name;
          version = last groupVersion;
          group =
            if version == (head groupVersion)
            then "core" else head groupVersion;
          kind = object.kind;
        in
        {
          resources.${group}.${version}.${kind}.${name} = object;
        })
      cfg.imports));

    kubernetes.objects = flatten (mapAttrsToList
      (_: type:
        mapAttrsToList (name: resource: moduleToAttrs resource)
          cfg.api.resources.${type.group}.${type.version}.${type.kind}
      )
      cfg.api.types);

    kubernetes.generated = k8s.mkHashedList {
      items = config.kubernetes.objects;
      labels."kubenix/project-name" = config.kubenix.project;
      labels."kubenix/k8s-version" = config.kubernetes.version;
    };

    kubernetes.result =
      pkgs.writeText "${config.kubenix.project}-generated.json" (builtins.toJSON cfg.generated);

    kubernetes.resultYAML =
      toMultiDocumentYaml "${config.kubenix.project}-generated.yaml" (config.kubernetes.objects);
  };
}

# K8S module defines kubernetes definitions for kubenix
{ options, config, lib, pkgs, k8s, ... }:
with lib; let
  versions = (import ../versions.nix).versions;
  cfg = config.kubernetes;

  gvkKeyFn = type: "${type.group}/${type.version}/${type.kind}";

  getDefaults = resource: group: version: kind:
    catAttrs "default" (filter
      (default:
        (resource == null || default.resource == null || default.resource == resource)
        && (default.group == null || default.group == group)
        && (default.version == null || default.version == version)
        && (default.kind == null || default.kind == kind)
      )
      cfg.api.defaults);

  moduleToAttrs = value:
    if isAttrs value
    then mapAttrs (_n: moduleToAttrs) (filterAttrs (n: v: v != null && !(hasPrefix "_" n)) value)
    else if isList value
    then map moduleToAttrs value
    else value;

  apiOptions = { config, ... }: {
    options = {
      definitions = mkOption {
        description = "Attribute set of kubernetes definitions";
      };

      defaults = mkOption {
        description = "Kubernetes defaults to apply to resources";
        type = types.listOf (types.submodule (_: {
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
    head (filter (v: v != -1) (imap0
      (i: v:
        if v == value
        then i
        else -1)
      lst));

  compareVersions = ver1: ver2:
    let
      getVersion = substring 1 10;
      splittedVer1 = builtins.splitVersion (getVersion ver1);
      splittedVer2 = builtins.splitVersion (getVersion ver2);

      v1 =
        if length splittedVer1 == 1
        then "${getVersion ver1}prod"
        else getVersion ver1;
      v2 =
        if length splittedVer2 == 1
        then "${getVersion ver2}prod"
        else getVersion ver2;
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
        (
          r1: r2:
            compareVersions r1.version r2.version > 0
        )
        resourceTypes)
    )
    customResourceTypesByAttrName;

  latestCustomResourceTypes = mapAttrsToList (_: last) customResourceTypesByAttrNameSortByVersion;

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
    } // (ct.module or {});

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
          inherit (ct) description;
          type = types.attrsOf (types.submodule module);
          default = { };
        };
      })
    cfg.customTypes)
  ++ (map
    (ct: { options, config, ... }:
      let
        module = customResourceModuleForType config ct;
      in
      {
        options.resources.${ct.attrName} = mkOption {
          inherit (ct) description;
          type = types.attrsOf (types.submodule module);
          default = { };
        };

        config.resources.${ct.group}.${ct.version}.${ct.kind} =
          mkAliasDefinitions options.resources.${ct.attrName};
      })
    latestCustomResourceTypes);

  coerceListOfSubmodulesToAttrs = submodule: keyFn:
    let
      mergeValuesByFn = keyFn: values:
        listToAttrs (map
          (value:
            nameValuePair (toString (keyFn value)) value
          )
          values);

      # Either value of type `finalType` or `coercedType`, the latter is
      # converted to `finalType` using `coerceFunc`.
      coercedTo = coercedType: coerceFunc: finalType:
        mkOptionType rec {
          name = "coercedTo";
          description = "${finalType.description} or ${coercedType.description}";
          check = x: finalType.check x || coercedType.check x;
          merge = loc: defs:
            let
              coerceVal = val:
                if finalType.check val
                then val
                else let coerced = coerceFunc val; in assert finalType.check coerced; coerced;
            in
            finalType.merge loc (map (def: def // { value = coerceVal def.value; }) defs);
          inherit (finalType) getSubOptions;
          inherit (finalType) getSubModules;
          substSubModules = m: coercedTo coercedType coerceFunc (finalType.substSubModules m);
          typeMerge = _t1: _t2: null;
          functor = (defaultFunctor name) // { wrapped = finalType; };
        };
    in
    coercedTo
      (types.listOf (types.submodule submodule))
      (mergeValuesByFn keyFn)
      (types.attrsOf (types.submodule submodule));

  # inject hashed names for referencing inside modules, example:
  # pod = {
  #   containers.nginx = {
  #     image = "nginx:1.25.1";
  #     volumeMounts = {
  #       "/etc/nginx".name = "config";
  #       "/var/lib/html".name = "static";
  #     };
  #   };
  #   volumes = {
  #     config.configMap.name = config.kubernetes.resources.configMaps.nginx-config.metadata.name;
  #     static.configMap.name = config.kubernetes.resources.configMaps.nginx-static.metadata.name;
  #   };
  # };
  optionalHashedNames = object:
    if cfg.enableHashedNames then
      recursiveUpdate object
        (mapAttrs
          (ks: v:
            if builtins.elem ks [ "configMaps" "secrets" ] then
              k8s.injectHashedNames v
            else
              v
          )
          object)
    else object;

  # inject hashed names in the output
  optionalHashedNames' = object: kind:
    if cfg.enableHashedNames && elem kind [ "ConfigMap" "Secret" ] then
      k8s.injectHashedNames object
    else object;
in
{
  imports = [ ./base.nix ];

  options.kubernetes = {
    kubeconfig = mkOption {
      description = "path to kubeconfig file (default: use $KUBECONFIG)";
      type = types.nullOr types.str;
      default = null;
      example = "/run/secrets/kubeconfig";
    };

    version = mkOption {
      description = "Kubernetes version to use";
      type = types.enum versions;
      default = lib.lists.last versions;
      example = "1.24";
    };

    namespace = mkOption {
      description = "Default namespace where to deploy kubernetes resources";
      type = types.nullOr types.str;
      default = null;
      example = "default";
    };

    customResources = mkOption {
      description = "Setup custom resources";
      type = types.listOf types.attrs;
      default = [ ];
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
          ./generated/v${cfg.version}.nix
          apiOptions
        ]
        ++ customResourceOptions;
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
      apply = optionalHashedNames;
    };

    customTypes = mkOption {
      description = "Custom resource types to make API for";
      example = {
        helmchartconfig = {
          attrName = "helmchartconfig";
          kind = "HelmChartConfig";
          version = "v1";
          group = "helm.cattle.io";
        };
      };
      type = coerceListOfSubmodulesToAttrs
        {
          options = {
            group = mkOption {
              description = "Custom type group";
              example = "helm.cattle.io";
              type = types.str;
            };

            version = mkOption {
              description = "Custom type version";
              example = "v1";
              type = types.str;
            };

            kind = mkOption {
              description = "Custom type kind";
              example = "HelmChartConfig";
              type = types.str;
            };

            name = mkOption {
              description = "Custom type resource name";
              type = types.nullOr types.str;
              default = null;
            };

            attrName = mkOption {
              description = "Name of the nixified attribute";
              # default = name;
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
      apply = items:
        sort
          (r1: r2:
            if elem r1.kind cfg.resourceOrder && elem r2.kind cfg.resourceOrder
            then indexOf cfg.resourceOrder r1.kind < indexOf cfg.resourceOrder r2.kind
            else if elem r1.kind cfg.resourceOrder
            then true
            else false
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

    enableHashedNames = mkOption {
      description = "Enable hashing of resource (ConfigMap,Secret) names";
      type = types.bool;
      default = false;
    };
  };

  config = {
    # features that module is defining
    _m.features = [ "k8s" ];

    # module propagation options
    _m.propagate = [
      {
        features = [ "k8s" ];
        module = _: {
          # propagate kubernetes version and namespace
          kubernetes.version = mkDefault cfg.version;
          kubernetes.namespace = mkDefault cfg.namespace;
        };
      }
      {
        features = [ "k8s" "submodule" ];
        module = { config, ... }: {
          # set module defaults
          kubernetes.api.defaults =
            (filter (default: default.propagate) cfg.api.defaults)
            ++ [
              # set module name and version for all kuberentes resources
              {
                default.metadata.labels = {
                  "kubenix/module-name" = config.submodule.name;
                  "kubenix/module-version" = config.submodule.version;
                };
              }
            ];
        };
      }
    ];

    # expose k8s helper methods as module argument
    _module.args.k8s = import ../lib/k8s { inherit lib; };

    kubernetes.api = mkMerge ([
      {
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
      }
    ]
    ++
    # import of yaml files
    (map
      (i:
        let
          # load yaml file
          object = importYAML i;
          groupVersion = splitString "/" object.apiVersion;
          inherit (object.metadata) name;
          version = last groupVersion;
          group =
            if version == (head groupVersion)
            then "core"
            else head groupVersion;
          inherit (object) kind;
        in
        {
          resources.${group}.${version}.${kind}.${name} = object;
        })
      cfg.imports));

    kubernetes.objects = flatten (mapAttrsToList
      (_: type:
        mapAttrsToList (_name: moduleToAttrs)
          (optionalHashedNames' cfg.api.resources.${type.group}.${type.version}.${type.kind} type.kind)
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
      toMultiDocumentYaml "${config.kubenix.project}-generated.yaml" config.kubernetes.objects;
  };
}

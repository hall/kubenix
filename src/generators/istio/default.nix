{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib, spec ? ./istio-schema.json }:

with lib;
let
  gen = rec {
    mkMerge = values: ''mkMerge [${concatMapStrings
(value: "
      ${value}
    ")
values}]'';

    toNixString = value:
      if isAttrs value || isList value
      then builtins.toJSON value
      else if isString value
      then ''"${value}"''
      else if value == null
      then "null"
      else builtins.toString value;

    removeEmptyLines = str: concatStringsSep "\n" (filter (l: (builtins.match "(  |)+" l) == null) (splitString "\n" str));

    mkOption =
      { description ? null
      , type ? null
      , default ? null
      , apply ? null
      }: removeEmptyLines ''mkOption {
          ${optionalString (description != null) "description = ${builtins.toJSON description};"}
          ${optionalString (type != null) ''type = ${type};''}
          ${optionalString (default != null) ''default = ${toNixString default};''}
          ${optionalString (apply != null) ''apply = ${apply};''}
        }'';

    mkOverride = priority: value: "mkOverride ${toString priority} ${toNixString value}";

    types = {
      unspecified = "types.unspecified";
      str = "types.str";
      int = "types.int";
      bool = "types.bool";
      attrs = "types.attrs";
      nullOr = val: "(types.nullOr ${val})";
      attrsOf = val: "(types.attrsOf ${val})";
      listOf = val: "(types.listOf ${val})";
      coercedTo = coercedType: coerceFunc: finalType:
        "(types.coercedTo ${coercedType} ${coerceFunc} ${finalType})";
      either = val1: val2: "(types.either ${val1} ${val2})";
      loaOf = type: "(types.loaOf ${type})";
    };

    hasTypeMapping = def:
      hasAttr "type" def &&
      elem def.type [ "string" "integer" "boolean" ];

    mergeValuesByKey = mergeKey: ''(mergeValuesByKey "${mergeKey}")'';

    mapType = def:
      if def.type == "string" then
        if hasAttr "format" def && def.format == "int-or-string"
        then types.either types.int types.str
        else types.str
      else if def.type == "integer" then types.int
      else if def.type == "number" then types.int
      else if def.type == "boolean" then types.bool
      else if def.type == "object" then types.attrs
      else throw "type ${def.type} not supported";

    submoduleOf = definitions: ref: ''(submoduleOf "${ref}")'';

    submoduleForDefinition = ref: name: kind: group: version:
      ''(submoduleForDefinition "${ref}" "${name}" "${kind}" "${group}" "${version}")'';

    coerceAttrsOfSubmodulesToListByKey = ref: mergeKey:
      ''(coerceAttrsOfSubmodulesToListByKey "${ref}" "${mergeKey}")'';

    attrsToList = "values: if values != null then mapAttrsToList (n: v: v) values else values";

    refDefinition = attr: head (tail (tail (splitString "/" attr."$ref")));
  };

  fixJSON = content: replaceStrings [ "\\u" ] [ "u" ] content;

  fetchSpecs = path: builtins.fromJSON (fixJSON (builtins.readFile path));

  genDefinitions = swagger: with gen; (mapAttrs
    (name: definition:
      # if $ref is in definition it means it's an alias of other definition
      if hasAttr "$ref" definition
      then definitions."${refDefinition definition}"

      else if !(hasAttr "properties" definition)
      then {
        type = mapType definition;
      }

      else {
        options = mapAttrs
          (propName: property:
            let
              isRequired = elem propName (definition.required or [ ]);
              requiredOrNot = type: if isRequired then type else types.nullOr type;
              optionProperties =
                # if $ref is in property it references other definition,
                # but if other definition does not have properties, then just take it's type
                if hasAttr "$ref" property then
                  if hasTypeMapping swagger.definitions.${refDefinition property} then {
                    type = requiredOrNot (mapType swagger.definitions.${refDefinition property});
                  }
                  else {
                    type = requiredOrNot (submoduleOf definitions (refDefinition property));
                  }

                else if !(hasAttr "type" property) then {
                  type = types.unspecified;
                }

                # if property has an array type
                else if property.type == "array" then

                # if reference is in items it can reference other type of another
                # definition
                  if hasAttr "$ref" property.items then

                  # if it is a reference to simple type
                    if hasTypeMapping swagger.definitions.${refDefinition property.items}
                    then {
                      type = requiredOrNot (types.listOf (mapType swagger.definitions.${refDefinition property.items}.type));
                    }

                    # if a reference is to complex type
                    else
                    # if x-kubernetes-patch-merge-key is set then make it an
                    # attribute set of submodules
                      if hasAttr "x-kubernetes-patch-merge-key" property
                      then
                        let
                          mergeKey = property."x-kubernetes-patch-merge-key";
                        in
                        {
                          type = requiredOrNot (coerceAttrsOfSubmodulesToListByKey (refDefinition property.items) mergeKey);
                          apply = attrsToList;
                        }

                      # in other case it's a simple list
                      else {
                        type = requiredOrNot (types.listOf (submoduleOf definitions (refDefinition property.items)));
                      }

                  # in other case it only references a simple type
                  else {
                    type = requiredOrNot (types.listOf (mapType property.items));
                  }

                else if property.type == "object" && hasAttr "additionalProperties" property
                then
                # if it is a reference to simple type
                  if (
                    hasAttr "$ref" property.additionalProperties &&
                    hasTypeMapping swagger.definitions.${refDefinition property.additionalProperties}
                  ) then {
                    type = requiredOrNot (types.attrsOf (mapType swagger.definitions.${refDefinition property.additionalProperties}));
                  }

                  else if hasAttr "$ref" property.additionalProperties
                  then {
                    type = requiredOrNot types.attrs;
                  }

                  # if is an array
                  else if property.additionalProperties.type == "array"
                  then {
                    type = requiredOrNot (types.loaOf (mapType property.additionalProperties.items));
                  }

                  else {
                    type = requiredOrNot (types.attrsOf (mapType property.additionalProperties));
                  }

                # just a simple property
                else {
                  type = requiredOrNot (mapType property);
                };
            in
            mkOption ({
              description = property.description or "";
            } // optionProperties)
          )
          definition.properties;
        config =
          let
            optionalProps = filterAttrs
              (propName: property:
                !(elem propName (definition.required or [ ]))
              )
              definition.properties;
          in
          mapAttrs (name: property: mkOverride 1002 null) optionalProps;
      }
    )
    swagger.definitions);

  genResources = swagger: (mapAttrsToList
    (name: property: rec {
      splittedType = splitString "." (removePrefix "me.snowdrop.istio.api." property.javaType);
      group = (concatStringsSep "." (take ((length splittedType) - 2) splittedType)) + ".istio.io";
      kind = removeSuffix "Spec" (last splittedType);
      version = last (take ((length splittedType) - 1) splittedType);
      ref = removePrefix "#/definitions/" property."$ref";
    })
    (filterAttrs
      (name: property:
        (hasPrefix "me.snowdrop.istio.api" property.javaType) &&
          hasSuffix "Spec" property.javaType
      )
      swagger.properties)) ++ (mapAttrsToList
    (name: property: rec {
      splittedType = splitString "." (removePrefix "me.snowdrop.istio.mixer." property.javaType);
      group = "config.istio.io";
      version = "v1alpha2";
      kind = head (tail splittedType);
      ref = removePrefix "#/definitions/" property."$ref";
    })
    (filterAttrs
      (name: property:
        (hasPrefix "me.snowdrop.istio.mixer" property.javaType) &&
          hasSuffix "Spec" property.javaType
      )
      swagger.properties));

  swagger = fetchSpecs spec;

  definitions = genDefinitions swagger;
in
pkgs.writeText "gen.nix" ''
  # This file was generated with kubenix k8s generator, do not edit
  {lib, config, ... }:
  
  with lib;
  
  let
    types = lib.types // rec {
      str = mkOptionType {
        name = \"str\";
        description = \"string\";
        check = isString;
        merge = mergeEqualOption;
      };
  
      # Either value of type `finalType` or `coercedType`, the latter is
      # converted to `finalType` using `coerceFunc`.
      coercedTo = coercedType: coerceFunc: finalType:
      mkOptionType rec {
        name = \"coercedTo\";
        description = \"\${finalType.description} or \${coercedType.description}\";
        check = x: finalType.check x || coercedType.check x;
        merge = loc: defs:
          let
            coerceVal = val:
              if finalType.check val then val
              else let
                coerced = coerceFunc val;
              in assert finalType.check coerced; coerced;
  
          in finalType.merge loc (map (def: def // { value = coerceVal def.value; }) defs);
        getSubOptions = finalType.getSubOptions;
        getSubModules = finalType.getSubModules;
        substSubModules = m: coercedTo coercedType coerceFunc (finalType.substSubModules m);
        typeMerge = t1: t2: null;
        functor = (defaultFunctor name) // { wrapped = finalType; };
      };
    };
  
    mkOptionDefault = mkOverride 1001;
  
    extraOptions = {
      kubenix = {};
    };
  
    mergeValuesByKey = mergeKey: values:
      listToAttrs (map
        (value: nameValuePair (
          if isAttrs value.\${mergeKey}
          then toString value.\${mergeKey}.content
          else (toString value.\${mergeKey})
        ) value)
      values);
  
    submoduleOf = ref: types.submodule ({name, ...}: {
      options = definitions.\"\${ref}\".options;
      config = definitions.\"\${ref}\".config;
    });
  
    submoduleWithMergeOf = ref: mergeKey: types.submodule ({name, ...}: let
      convertName = name:
        if definitions.\"\${ref}\".options.\${mergeKey}.type == types.int
        then toInt name
        else name;
    in {
      options = definitions.\"\${ref}\".options;
      config = definitions.\"\${ref}\".config // {
        \${mergeKey} = mkOverride 1002 (convertName name);
      };
    });
  
    submoduleForDefinition = ref: resource: kind: group: version:
      types.submodule ({name, ...}: {
        options = definitions.\"\${ref}\".options // extraOptions;
        config = mkMerge ([
          definitions.\"\${ref}\".config
          {
            kind = mkOptionDefault kind;
            apiVersion = mkOptionDefault version;
  
            # metdata.name cannot use option default, due deep config
            metadata.name = mkOptionDefault name;
          }
        ] ++ (config.defaults.\${resource} or [])
          ++ (config.defaults.all or []));
      });
  
    coerceAttrsOfSubmodulesToListByKey = ref: mergeKey: (types.coercedTo
      (types.listOf (submoduleOf ref))
      (mergeValuesByKey mergeKey)
      (types.attrsOf (submoduleWithMergeOf ref mergeKey))
    );
  
    definitions = {
      ${concatStrings (mapAttrsToList
  (name: value: "
      \"${name}\" = {${optionalString (hasAttr "options" value) "
        options = {${concatStrings (mapAttrsToList
  (name: value: "
          \"${name}\" = ${value};
        ")
  value.options)}};
      "}${optionalString (hasAttr "config" value) "
        config = {${concatStrings (mapAttrsToList
  (name: value: "
          \"${name}\" = ${value};
        ")
  value.config)}};
      "}};
      ")
  definitions)}
    } // (import ./overrides.nix {inheirt definitions lib;}));
  in {
    kubernetes.customResources = [
    ${concatMapStrings
  (resource: ''{
      group = "${resource.group}";
      version = "${resource.version}";
      kind = "${resource.kind}";
      description = "";
      module = definitions."${resource.ref}";
    }'')
  (genResources swagger)}
    ];
  }
''

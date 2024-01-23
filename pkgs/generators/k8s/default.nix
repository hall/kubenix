{ name, pkgs, lib, spec }:
with lib; let
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

    removeEmptyLines = str: concatStringsSep "\n" (filter (l: builtins.match "[[:space:]]*" l != [ ]) (splitString "\n" str));

    mkOption = { description ? null, type ? null, default ? null, apply ? null }:
      removeEmptyLines ''        mkOption {
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
      coercedTo = coercedType: coerceFunc: finalType: "(types.coercedTo ${coercedType} ${coerceFunc} ${finalType})";
      either = val1: val2: "(types.either ${val1} ${val2})";
      loaOf = type: "(types.loaOf ${type})";
    };

    hasTypeMapping = def: hasAttr "type" def && elem def.type [ "string" "integer" "boolean" ];

    mergeValuesByKey = mergeKey: ''(mergeValuesByKey "${mergeKey}")'';

    mapType = def:
      if def.type == "string"
      then
        if hasAttr "format" def && def.format == "int-or-string"
        then types.either types.int types.str
        else types.str
      else if def.type == "integer"
      then types.int
      else if def.type == "number"
      then types.int
      else if def.type == "boolean"
      then types.bool
      else if def.type == "object"
      then types.attrs
      else throw "type ${def.type} not supported";

    submoduleOf = _definitions: ref: ''(submoduleOf "${ref}")'';

    submoduleForDefinition = ref: name: kind: group: version: ''(submoduleForDefinition "${ref}" "${name}" "${kind}" "${group}" "${version}")'';

    coerceAttrsOfSubmodulesToListByKey = ref: mergeKey: listMapKeys: ''(coerceAttrsOfSubmodulesToListByKey "${ref}" "${mergeKey}" [${concatStringsSep " " (map (key: "\"${toString key}\"") listMapKeys)}])'';

    attrsToList = "attrsToList";

    refDefinition = attr: head (tail (tail (splitString "/" attr."$ref")));
  };

  refType = attr: head (tail (tail (splitString "/" attr."$ref")));

  compareVersions = ver1: ver2:
    let
      getVersion = substring 1 10;
      splitVersion = v: builtins.splitVersion (getVersion v);
      isAlpha = v: elem "alpha" (splitVersion v);
      patchVersion = v:
        if isAlpha v
        then ""
        else if length (splitVersion v) == 1
        then "${getVersion v}prod"
        else getVersion v;

      v1 = patchVersion ver1;
      v2 = patchVersion ver2;
    in
    builtins.compareVersions v1 v2;

  fixJSON = replaceStrings [ "\\u" ] [ "u" ];

  fetchSpecs = path: builtins.fromJSON (fixJSON (builtins.readFile path));

  genDefinitions = swagger: with gen; mapAttrs
    (_name: definition:
      # if $ref is in definition it means it's an alias of other definition
      if hasAttr "$ref" definition
      then definitions."${refDefinition definition}"
      else if !(hasAttr "properties" definition)
      then { }
      # in other case it's an actual definition
      else {
        options =
          mapAttrs
            (
              propName: property:
                let
                  isRequired = elem propName (definition.required or [ ]);
                  requiredOrNot = type:
                    if isRequired
                    then type
                    else types.nullOr type;
                  optionProperties =
                    # if $ref is in property it references other definition,
                    # but if other definition does not have properties, then just take it's type
                    if hasAttr "$ref" property
                    then
                      if hasTypeMapping swagger.definitions.${refDefinition property}
                      then {
                        type = requiredOrNot (mapType swagger.definitions.${refDefinition property});
                      }
                      else {
                        type =
                          if (refDefinition property) == _name
                          then types.unspecified # do not allow self-referential values
                          else requiredOrNot (submoduleOf definitions (refDefinition property));
                      }
                    # if property has an array type
                    else if property.type == "array"
                    then
                    # if reference is in items it can reference other type of another
                    # definition
                      if hasAttr "$ref" property.items
                      then
                      # if it is a reference to simple type
                        if hasTypeMapping swagger.definitions.${refDefinition property.items}
                        then {
                          type = requiredOrNot (types.listOf (mapType swagger.definitions.${refDefinition property.items}.type));
                        }
                        # if a reference is to complex type
                        else
                          if hasAttr "x-kubernetes-patch-merge-key" property
                          then
                            let
                              mergeKey = property."x-kubernetes-patch-merge-key";
                            in
                            {
                              type = requiredOrNot (coerceAttrsOfSubmodulesToListByKey (refDefinition property.items) mergeKey (
                                if hasAttr "x-kubernetes-list-map-keys" property
                                then property."x-kubernetes-list-map-keys"
                                else [ ]
                              ));
                              apply = attrsToList;
                            }
                          # in other case it's a simple list
                          else {
                            type =
                              if (refDefinition property.items) == _name
                              then types.unspecified # do not allow self-referential values
                              else requiredOrNot (types.listOf (submoduleOf definitions (refDefinition property.items)));
                          }
                      # in other case it only references a simple type
                      else {
                        type = requiredOrNot (types.listOf (mapType property.items));
                      }
                    else if property.type == "object" && hasAttr "additionalProperties" property
                    then
                    # if it is a reference to simple type
                      if
                        (
                          hasAttr "$ref" property.additionalProperties
                          && hasTypeMapping swagger.definitions.${refDefinition property.additionalProperties}
                        )
                      then {
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
                }
                // optionProperties)
            )
            definition.properties;
        config =
          let
            optionalProps =
              filterAttrs
                (
                  propName: _property:
                    !(elem propName (definition.required or [ ]))
                )
                definition.properties;
          in
          mapAttrs (_name: _property: mkOverride 1002 null) optionalProps;
      }
    )
    swagger.definitions;

  mapCharPairs = f: s1: s2: concatStrings (imap0
    (i: c1:
      f i c1 (
        if i >= stringLength s2
        then ""
        else elemAt (stringToCharacters s2) i
      )
    )
    (stringToCharacters s1));

  getAttrName = resource: kind: mapCharPairs
    (i: c1: c2:
      if hasPrefix "API" kind && i == 0
      then "A"
      else if i == 0
      then c1
      else if c2 == "" || (toLower c2) != c1
      then c1
      else c2
    )
    resource
    kind;

  genResourceTypes = swagger: mapAttrs'
    (name: path:
      let
        ref = refType (head path.post.parameters).schema;
        group' = path.post."x-kubernetes-group-version-kind".group;
        version' = path.post."x-kubernetes-group-version-kind".version;
        kind' = path.post."x-kubernetes-group-version-kind".kind;
        name' = last (splitString "/" name);
        attrName = getAttrName name' kind';
      in
      nameValuePair ref {
        inherit ref attrName;

        name = name';
        group =
          if group' == ""
          then "core"
          else group';
        version = version';
        kind = kind';
        inherit (swagger.definitions.${ref}) description;
        defintion = refDefinition (head path.post.parameters).schema;
      })
    (filterAttrs
      (
        _name: path:
          hasAttr "post" path
          && path.post."x-kubernetes-action" == "post"
      )
      swagger.paths);

  swagger = fetchSpecs spec;
  definitions = genDefinitions swagger;
  resourceTypes = genResourceTypes swagger;

  resourceTypesByKind = zipAttrs (mapAttrsToList
    (_name: resourceType: {
      ${resourceType.kind} = resourceType;
    })
    resourceTypes);

  resourcesTypesByKindSortByVersion = mapAttrs
    (_kind: resourceTypes:
      reverseList (sort
        (
          r1: r2:
            compareVersions r1.version r2.version > 0
        )
        resourceTypes)
    )
    resourceTypesByKind;

  latestResourceTypesByKind = mapAttrs (_kind: last) resourcesTypesByKindSortByVersion;

  genResourceOptions = resource:
    with gen; let
      submoduleForDefinition' = definition:
        submoduleForDefinition
          definition.ref
          definition.name
          definition.kind
          definition.group
          definition.version;
    in
    mkOption {
      inherit (resource) description;
      type = types.attrsOf (submoduleForDefinition' resource);
      default = { };
    };

  generated = ''
    # This file was generated with kubenix k8s generator, do not edit
    { lib, options, config, ... }:

    with lib;

    let
      hasAttrNotNull = attr: set: hasAttr attr set && !isNull set.''${attr};

      attrsToList = values:
        if values != null
        then
          sort (a: b:
            if (hasAttrNotNull "_priority" a && hasAttrNotNull "_priority" b)
            then a._priority < b._priority
            else false
          ) (mapAttrsToList (n: v: v) values)
        else
          values;

      getDefaults = resource: group: version: kind:
        catAttrs "default" (filter (default:
          (default.resource == null || default.resource == resource) &&
          (default.group == null || default.group == group) &&
          (default.version == null || default.version == version) &&
          (default.kind == null || default.kind == kind)
        ) config.defaults);

      types = lib.types // rec {
        str = mkOptionType {
          name = "str";
          description = "string";
          check = isString;
          merge = mergeEqualOption;
        };

        # Either value of type `finalType` or `coercedType`, the latter is
        # converted to `finalType` using `coerceFunc`.
        coercedTo = coercedType: coerceFunc: finalType:
        mkOptionType rec {
          name = "coercedTo";
          description = "''${finalType.description} or ''${coercedType.description}";
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

      mergeValuesByKey = mergeKey: listMapKeys: values:
        listToAttrs (imap0
          (i: value: nameValuePair (
            (concatStringsSep "" (map (key:
                if value ? ''${key}
                then
                  if isAttrs value.''${key}
                  then toString value.''${key}.content
                  else (toString value.''${key})
                else ""
              ) (unique ([mergeKey] ++ listMapKeys))))
          ) (value // { _priority = i; }))
        values);

      submoduleOf = ref: types.submodule ({name, ...}: {
        options = definitions."''${ref}".options or {};
        config = definitions."''${ref}".config or {};
      });

      submoduleWithMergeOf = ref: mergeKey: types.submodule ({name, ...}: let
        convertName = name:
          if definitions."''${ref}".options.''${mergeKey}.type == types.int
          then toInt name
          else name;
      in {
        options = definitions."''${ref}".options // {
          # position in original array
          _priority = mkOption { type = types.nullOr types.int; default = null; };
        };
        config = definitions."''${ref}".config // {
          ''${mergeKey} = mkOverride 1002 (convertName name);
        };
      });

      submoduleForDefinition = ref: resource: kind: group: version: let
        apiVersion = if group == "core" then version else "''${group}/''${version}";
      in types.submodule ({name, ...}: {
        imports = getDefaults resource group version kind;
        options = definitions."''${ref}".options;
        config = mkMerge [
          definitions."''${ref}".config
          {
            kind = mkOptionDefault kind;
            apiVersion = mkOptionDefault apiVersion;

            # metdata.name cannot use option default, due deep config
            metadata.name = mkOptionDefault name;
          }
        ];
      });

      coerceAttrsOfSubmodulesToListByKey = ref: mergeKey: listMapKeys: (types.coercedTo
        (types.listOf (submoduleOf ref))
        (mergeValuesByKey mergeKey listMapKeys)
        (types.attrsOf (submoduleWithMergeOf ref mergeKey))
      );

      definitions = {
        ${concatStrings (mapAttrsToList (name: value: ''
        "${name}" = {
          ${optionalString (hasAttr "options" value) "
            options = {${concatStrings (mapAttrsToList (name: value: ''
            "${name}" = ${value};
          '')
          value.options)}};
            "}

          ${optionalString (hasAttr "config" value) ''
          config = {${concatStrings (mapAttrsToList (name: value: ''
              "${name}" = ${value};
            '')
            value.config)}};
        ''}
        };
      '')
      definitions)}
      };
    in {
      # all resource versions
      options = {
        resources = {
          ${concatStrings (mapAttrsToList (_: rt: ''
        "${rt.group}"."${rt.version}"."${rt.kind}" = ${genResourceOptions rt};
      '')
      resourceTypes)}
        } // {
          ${concatStrings (mapAttrsToList (_: rt: ''
        "${rt.attrName}" = ${genResourceOptions rt};
      '')
      latestResourceTypesByKind)}
        };
      };

      config = {
        # expose resource definitions
        inherit definitions;

        # register resource types
        types = [${concatStrings (mapAttrsToList (_: rt: ''      {
                name = "${rt.name}";
                group = "${rt.group}";
                version = "${rt.version}";
                kind = "${rt.kind}";
                attrName = "${rt.attrName}";
              }'')
    resourceTypes)}];

        resources = {
          ${concatStrings (mapAttrsToList (_: rt: ''
        "${rt.group}"."${rt.version}"."${rt.kind}" =
          mkAliasDefinitions options.resources."${rt.attrName}";
      '')
      latestResourceTypesByKind)}
        };
      };
    }
  '';
in
pkgs.runCommand "k8s-${name}-gen.nix"
{
  buildInputs = [ pkgs.nixpkgs-fmt ];
} ''
  cat << 'GENERATED' > ./raw
  ${generated}
  GENERATED

  nixpkgs-fmt ./raw
  cp ./raw $out
''

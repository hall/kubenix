{
  pkgs,
  options,
}: let
  extraSources = [];
  lib = pkgs.lib;

  optionsListVisible =
    lib.filter (opt: opt.visible && !opt.internal)
    (lib.optionAttrSetToDocList options);

  # Replace functions by the string <function>
  substFunction = x:
    if builtins.isAttrs x
    then lib.mapAttrs (name: substFunction) x
    else if builtins.isList x
    then map substFunction x
    else if lib.isFunction x
    then "<function>"
    else if isPath x
    then toString x
    else x;

  isPath = x: (builtins.typeOf x) == "path";

  optionsListDesc = lib.flip map optionsListVisible (
    opt:
      opt
      // {
        description = let
          attempt = builtins.tryEval opt.description;
        in
          if attempt.success
          then attempt.value
          else "N/A";
        declarations = map stripAnyPrefixes opt.declarations;
      }
      // lib.optionalAttrs (opt ? example) {
        example = substFunction opt.example;
      }
      // lib.optionalAttrs (opt ? default) {
        default = substFunction opt.default;
      }
      // lib.optionalAttrs (opt ? type) {
        type = substFunction opt.type;
      }
      // lib.optionalAttrs
      (opt ? relatedPackages && opt.relatedPackages != [])
      {
        relatedPackages = genRelatedPackages opt.relatedPackages;
      }
  );

  genRelatedPackages = packages: let
    unpack = p:
      if lib.isString p
      then {name = p;}
      else if lib.isList p
      then {path = p;}
      else p;
    describe = args: let
      title = args.title or null;
      name = args.name or (lib.concatStringsSep "." args.path);
      path = args.path or [args.name];
      package =
        args.package
        or (lib.attrByPath path
          (throw
            "Invalid package attribute path '${toString path}'")
          pkgs);
    in
      "<listitem>"
      + "<para><literal>${lib.optionalString (title != null)
        "${title} aka "}pkgs.${name} (${package.meta.name})</literal>"
      + lib.optionalString (!package.meta.available)
      " <emphasis>[UNAVAILABLE]</emphasis>"
      + ": ${package.meta.description or "???"}.</para>"
      + lib.optionalString (args ? comment)
      "\n<para>${args.comment}</para>"
      + lib.optionalString (package.meta ? longDescription)
      "\n<programlisting>${package.meta.longDescription}"
      + "</programlisting>"
      + "</listitem>";
  in "<itemizedlist>${lib.concatStringsSep "\n" (map (p:
    describe (unpack p))
  packages)}</itemizedlist>";

  optionLess = a: b: let
    ise = lib.hasPrefix "enable";
    isp = lib.hasPrefix "package";
    cmp =
      lib.splitByAndCompare ise lib.compare
      (lib.splitByAndCompare isp lib.compare lib.compare);
  in
    lib.compareLists cmp a.loc b.loc < 0;

  prefixesToStrip = map (p: "${toString p}/") ([../../..] ++ extraSources);
  stripAnyPrefixes = lib.flip (lib.fold lib.removePrefix) prefixesToStrip;

  ###############################################################################

  # This is the REAL meat of what we were after.
  # Output this however you want.
  optionsList = lib.sort optionLess optionsListDesc;

  optionsJSON = builtins.unsafeDiscardStringContext (builtins.toJSON
    (builtins.listToAttrs (map
      (o: {
        name = o.name;
        value = removeAttrs o [
          # Select the fields you want to drop here:
          "name"
          "visible"
          "internal"
          "loc"
          "readOnly"
        ];
      })
      optionsList)));
in
  pkgs.writeText "options.json" optionsJSON

{pkgs}: let
  sets = pkgs.lib.attrsets;
in
  {}
  // (
    sets.mapAttrs' (name: value: sets.nameValuePair "generate-${name}" value)
    (builtins.removeAttrs (pkgs.callPackage ./generators {}) ["override" "overrideDerivation"])
  )

{ self, ... }:
{
  perSystem = { pkgs, self', evalModules, ... }: {
    packages = {
      default = pkgs.callPackage ../pkgs/kubenix.nix {
        inherit evalModules;
      };
      docs = import ../docs {
        inherit pkgs;
        options = (evalModules {
          modules = builtins.attrValues self.nixosModules.kubenix;
        }).options;
      };
    } // pkgs.lib.attrsets.mapAttrs' (name: value: pkgs.lib.attrsets.nameValuePair "generate-${name}" value)
      (builtins.removeAttrs (pkgs.callPackage ../pkgs/generators { }) [ "override" "overrideDerivation" ])
    // (
      # TODO: fix default.nix in all examples so they don't rely on inpure builtins.currentSystem
      #   and then we can add all of them here.
      pkgs.lib.attrsets.genAttrs' [
        "namespaces"
        "deployment"
        "custom-resources"
      ]
        (name: pkgs.lib.nameValuePair
          ("example-" + name)
          (self'.packages.default.override {
            module = ../docs/content/examples + "/${name}/module.nix";
          }))
    );
  };
}

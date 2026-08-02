{ self, ... }:
{
  # `formatting` is contributed by the treefmt-nix flakeModule (see formatter.nix).
  perSystem = { pkgs, self', evalModules, ... }:
    let
      wasSuccess = suite:
        if suite.success
        then pkgs.runCommand "testing-suite-config-assertions-for-${suite.name}-succeeded" { } "echo success > $out"
        else pkgs.runCommand "testing-suite-config-assertions-for-${suite.name}-failed" { } "exit 1";
      examples = import ../docs/content/examples;
      mkK8STests = attrs:
        (import ../tests { inherit evalModules; })
          ({ registry = "docker.io/gatehub"; } // attrs);
    in
    {
      checks = {
        # Pins the interface that `evalModules` and the `kubenix` special argument expose to
        # module authors, so refactors of the evaluator have something to be measured against.
        eval-modules = import ../tests/eval-modules.nix {
          inherit pkgs;
          # Imported directly rather than taken from perSystem, so this check covers the entry
          # point a non-flake consumer uses. Every other check reaches it through the flake.
          evalModules = import ../lib/eval-modules.nix { inherit pkgs; };
        };

        overlay = import ../tests/overlay.nix {
          inherit pkgs;
          overlay = self.overlays.default;
        };

        # Check that all packages build
        # TODO: impure examples (helm/image/pod) aren't packages yet; once their default.nix
        #   is pure they join `self'.packages` and build here automatically (matches packages.nix).
        packages = pkgs.linkFarm "kubenix-packages"
          (pkgs.lib.mapAttrsToList (name: path: { inherit name path; }) self'.packages);

        # TODO: access "success" derivation with nice testing utils for nice output
        testing = wasSuccess examples.testing.config.testing;
        label-filtering = pkgs.callPackage ../tests/label-filtering.nix {
          kubenix = self'.packages.default;
        };
        docker-multiple-registries = import ../tests/docker/multiple-registries.nix {
          inherit pkgs;
          inherit (self.nixosModules) kubenix;
          inherit evalModules;
          images = pkgs.callPackage ../tests/images.nix { };
        };
        docker-image-from-package = import ../tests/docker/image-from-package.nix {
          inherit pkgs;
          inherit (self.nixosModules) kubenix;
          inherit evalModules;
          images = pkgs.callPackage ../tests/images.nix { };
        };
      } // builtins.listToAttrs (builtins.map
        (v: {
          name = "test-k8s-${builtins.replaceStrings ["."] ["_"] v}";
          value = wasSuccess (mkK8STests { k8sVersion = v; });
        })
        (import ../versions.nix).versions);
    };
}

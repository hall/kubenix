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

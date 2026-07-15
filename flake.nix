{
  description = "Kubernetes management with nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    systems.url = "github:nix-systems/default";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, systems, flake-parts, import-tree, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (import-tree ./flake)
    // (
    let
      eachSystem = f: inputs.nixpkgs.lib.genAttrs (import systems)
        (system: f inputs.nixpkgs.legacyPackages.${system});
    in
    {
      nixosModules.kubenix = import ./modules;

      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            dive
            k9s
            k3d
            kubie
          ];
        };
      });

      treefmtEval = eachSystem (pkgs: inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs = {
          nixpkgs-fmt.enable = true;
          black.enable = true;
          prettier.enable = true;
          shfmt.enable = true;
        };
        settings.global.excludes = [
          "docs/themes/*"
          "docs/layouts/*"
          "modules/generated/*"
        ];
      });

      formatter = eachSystem (pkgs: (self.treefmtEval.${pkgs.system}).config.build.wrapper);

      checks = eachSystem (pkgs:
        let
          wasSuccess = suite:
            if suite.success
            then pkgs.runCommand "testing-suite-config-assertions-for-${suite.name}-succeeded" { } "echo success > $out"
            else pkgs.runCommand "testing-suite-config-assertions-for-${suite.name}-failed" { } "exit 1";
          examples = import ./docs/content/examples;
          mkK8STests = attrs:
            (import ./tests { evalModules = self.evalModules.${pkgs.stdenv.hostPlatform.system}; })
              ({ registry = "docker.io/gatehub"; } // attrs);
        in
        {
          formatting = (self.treefmtEval.${pkgs.system}).config.build.check self;
          # TODO: access "success" derivation with nice testing utils for nice output
          testing = wasSuccess examples.testing.config.testing;
          label-filtering = pkgs.callPackage ./tests/label-filtering.nix {
            kubenix = self.packages.${pkgs.system}.default;
          };
          docker-multiple-registries = import ./tests/docker/multiple-registries.nix {
            inherit pkgs;
            inherit (self.nixosModules) kubenix;
            evalModules = self.evalModules.${pkgs.stdenv.hostPlatform.system};
            images = pkgs.callPackage ./tests/images.nix { };
          };
          docker-image-from-package = import ./tests/docker/image-from-package.nix {
            inherit pkgs;
            inherit (self.nixosModules) kubenix;
            evalModules = self.evalModules.${pkgs.stdenv.hostPlatform.system};
            images = pkgs.callPackage ./tests/images.nix { };
          };
        } // builtins.listToAttrs (builtins.map
          (v: {
            name = "test-k8s-${builtins.replaceStrings ["."] ["_"] v}";
            value = wasSuccess (mkK8STests { k8sVersion = v; });
          })
          (import ./versions.nix).versions)
      );
    });
}

{
  description = "Kubernetes management with nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, systems, ... }:
    let
      eachSystem = f: inputs.nixpkgs.lib.genAttrs (import systems)
        (system: f inputs.nixpkgs.legacyPackages.${system});
    in
    {
      nixosModules.kubenix = import ./modules;

      overlays.default = _final: prev: {
        kubenix.evalModules = self.evalModules.${prev.system};
      };

      # evalModules with same interface as lib.evalModules and kubenix as special argument
      evalModules = eachSystem (pkgs:
        attrs @ { module ? null, modules ? [ module ], ... }:
        let
          lib' = pkgs.lib.extend (lib: _self: import ./lib/upstreamables.nix { inherit lib pkgs; });
          attrs' = builtins.removeAttrs attrs [ "module" ];
        in
        lib'.evalModules (pkgs.lib.recursiveUpdate
          {
            modules = modules ++ [{
              config._module.args = {
                inherit pkgs;
                name = "default";
              };
            }];
            specialArgs = {
              pkgs = import inputs.nixpkgs {
                inherit (pkgs) system;
                overlays = [ self.overlays.default ];
                config.allowUnsupportedSystem = true;
              };

              kubenix = {
                lib = import ./lib { inherit pkgs; inherit (pkgs) lib; };
                evalModules = self.evalModules.${pkgs.system};
                modules = self.nixosModules.kubenix;
              };
            };
          }
          attrs')
      );

      packages = eachSystem (pkgs: {
        default = pkgs.callPackage ./pkgs/kubenix.nix {
          evalModules = self.evalModules.${pkgs.system};
        };
        docs = import ./docs {
          inherit pkgs;
          options = (self.evalModules.${pkgs.system} {
            modules = builtins.attrValues (builtins.removeAttrs
              # the submodules module currently doesn't evaluate:
              #     error: No module found ‹name›/latest
              # not sure how important that documentation is at this time
              self.nixosModules.kubenix [ "submodule" "submodules" ]);
          }).options;
        };
      } // pkgs.lib.attrsets.mapAttrs' (name: value: pkgs.lib.attrsets.nameValuePair "generate-${name}" value)
        (builtins.removeAttrs (pkgs.callPackage ./pkgs/generators { }) [ "override" "overrideDerivation" ])
      );

      apps = eachSystem (pkgs: {
        docs = {
          type = "app";
          program = (pkgs.writeShellScript "gen-docs" ''
            set -eo pipefail

            # generate json object of module options
            nix build '.#docs' -o ./docs/data/options.json

            # remove all old module pages
            rm ./docs/content/modules/[!_]?*.md || true

            # create a page for each module in hugo
            for mod in ${builtins.toString (builtins.attrNames self.nixosModules.kubenix)}; do
              [[ $mod == "base" ]] && mod=kubenix
              [[ $mod == "k8s" ]] && mod=kubernetes
              [[ $mod == "submodule"* ]] && continue
              echo "&nbsp; {{< options >}}" > ./docs/content/modules/$mod.md
            done

            # build the site
            cd docs && ${pkgs.hugo}/bin/hugo "$@"
          '').outPath;
        };

        generate = {
          type = "app";
          program = (pkgs.writeShellScript "gen-modules" ''
            set -eo pipefail
            dir=./modules/generated

            rm -rf $dir
            mkdir $dir
            nix build '.#generate-k8s'
            cp ./result/* $dir/

            rm result
          '').outPath;
        };
      });

      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            dive
            k9s
            kube3d
            kubie
          ];
        };
      });

      formatter = eachSystem (pkgs: (inputs.treefmt.lib.evalModule pkgs {
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
      }).config.build.wrapper);

      checks = eachSystem (pkgs:
        let
          wasSuccess = suite:
            if suite.success
            then pkgs.runCommandNoCC "testing-suite-config-assertions-for-${suite.name}-succeeded" { } "echo success > $out"
            else pkgs.runCommandNoCC "testing-suite-config-assertions-for-${suite.name}-failed" { } "exit 1";
          examples = import ./docs/content/examples;
          mkK8STests = attrs:
            (import ./tests { evalModules = self.evalModules.${pkgs.system}; })
              ({ registry = "docker.io/gatehub"; } // attrs);
        in
        {
          # TODO: access "success" derivation with nice testing utils for nice output
          testing = wasSuccess examples.testing.config.testing;
        } // builtins.listToAttrs (builtins.map
          (v: {
            name = "test-k8s-${builtins.replaceStrings ["."] ["_"] v}";
            value = wasSuccess (mkK8STests { k8sVersion = v; });
          })
          (import ./versions.nix).versions)
      );
    };
}

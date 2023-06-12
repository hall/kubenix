{
  description = "Kubernetes management with nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = inputs @ {self, ...}:
    (inputs.flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [self.overlays.default];
          config.allowUnsupportedSystem = true;
        };

        inherit (pkgs) lib;

        kubenix = {
          lib = import ./lib {inherit lib pkgs;};
          evalModules = self.evalModules.${system};
          modules = self.nixosModules.kubenix;
        };

        # evalModules with same interface as lib.evalModules and kubenix as
        # special argument
        evalModules = attrs @ {
          module ? null,
          modules ? [module],
          ...
        }: let
          lib' = lib.extend (lib: _self: import ./lib/upstreamables.nix {inherit lib pkgs;});
          attrs' = builtins.removeAttrs attrs ["module"];
        in
          lib'.evalModules (lib.recursiveUpdate
            {
              modules =
                modules
                ++ [
                  {
                    config._module.args = {
                      inherit pkgs;
                      name = "default";
                    };
                  }
                ];
              specialArgs = {
                inherit kubenix;
                inherit pkgs;
              };
            }
            attrs');
      in {
        inherit evalModules pkgs;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # formatters
            alejandra
            black
            nodePackages.prettier
            nodePackages.prettier-plugin-toml
            shfmt
            treefmt

            # extra tools
            dive
            fd
            k9s
            kube3d
            kubie
            hugo
          ];
          packages = [
            (pkgs.writeShellScriptBin "evalnix" ''
              # check nix parsing
              fd --extension nix --exec nix-instantiate --parse --quiet {} >/dev/null
            '')
          ];
          # KUBECONFIG = "kubeconfig.json";
          shellHook = ''
            export NODE_PATH="${pkgs.nodePackages.prettier-plugin-toml}/lib/node_modules:$NODE_PATH"
          '';
        };

        formatter = pkgs.treefmt;

        apps = {
          docs = inputs.flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "gen-docs" ''
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
              cd docs && ${pkgs.hugo}/bin/hugo $@
            '';
          };
          generate = inputs.flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "gen-modules" ''
              set -eo pipefail
              dir=./modules/generated

              rm -rf $dir
              mkdir $dir
              nix build '.#generate-k8s'
              cp ./result/* $dir/

              rm result
            '';
          };
        };

        packages =
          inputs.flake-utils.lib.flattenTree
          {
            inherit (pkgs) kubernetes kubectl;
          }
          // {
            cli = pkgs.callPackage ./pkgs/kubenix.nix {
              inherit (self.packages.${system});
            };
            default = self.packages.${system}.cli;
            docs = import ./docs {
              inherit pkgs;
              options =
                (self.evalModules.${system} {
                  modules = builtins.attrValues (builtins.removeAttrs
                    # the submodules module currently doesn't evaluate:
                    #     error: No module found ‹name›/latest
                    # not sure how important that documentation is a this time
                    self.nixosModules.kubenix ["submodule" "submodules"]);
                })
                .options;
            };
          }
          // import ./jobs {
            inherit pkgs;
          };

        checks = let
          wasSuccess = suite:
            if suite.success
            then pkgs.runCommandNoCC "testing-suite-config-assertions-for-${suite.name}-succeeded" {} "echo success > $out"
            else pkgs.runCommandNoCC "testing-suite-config-assertions-for-${suite.name}-failed" {} "exit 1";
          examples = import ./docs/content/examples;
          mkK8STests = attrs:
            (import ./tests {inherit evalModules;})
            ({registry = "docker.io/gatehub";} // attrs);
        in
          {
            # TODO: access "success" derivation with nice testing utils for nice output
            testing = wasSuccess examples.testing.config.testing;
          }
          // builtins.listToAttrs (builtins.map
            (v: {
              name = "test-k8s-${builtins.replaceStrings ["."] ["_"] v}";
              value = wasSuccess (mkK8STests {k8sVersion = v;});
            })
            (import ./versions.nix).versions);
      }
    ))
    // {
      nixosModules.kubenix = import ./modules;
      overlays.default = _final: prev: {
        kubenix.evalModules = self.evalModules.${prev.system};
      };
    };
}

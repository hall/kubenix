{
  description = "Kubernetes resource builder using nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
    devshell-flake.url = "github:numtide/devshell";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    devshell-flake,
  }:
    (flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            self.overlay
            devshell-flake.overlay
          ];
          config = {allowUnsupportedSystem = true;};
        };

        lib = pkgs.lib;

        kubenix = {
          lib = import ./lib {inherit lib pkgs;};
          evalModules = self.evalModules.${system};
          modules = self.modules;
        };

        # evalModules with same interface as lib.evalModules and kubenix as
        # special argument
        evalModules = attrs @ {
          module ? null,
          modules ? [module],
          ...
        }: let
          lib' = lib.extend (lib: self: import ./lib/upstreamables.nix {inherit lib pkgs;});
          attrs' = builtins.removeAttrs attrs ["module"];
        in
          lib'.evalModules (lib.recursiveUpdate
            {
              inherit modules;
              specialArgs = {inherit kubenix;};
              args = {
                inherit pkgs;
                name = "default";
              };
            }
            attrs');
      in {
        inherit evalModules;

        jobs = import ./jobs {inherit pkgs;};

        devShell = with pkgs;
          devshell.mkShell
          {imports = [(devshell.importTOML ./devshell.toml)];};

        packages = flake-utils.lib.flattenTree {
          inherit (pkgs) kubernetes kubectl;
        };

        checks = let
          wasSuccess = suite:
            if suite.success == true
            then pkgs.runCommandNoCC "testing-suite-config-assertions-for-${suite.name}-succeeded" {} "echo success > $out"
            else pkgs.runCommandNoCC "testing-suite-config-assertions-for-${suite.name}-failed" {} "exit 1";
          mkExamples = attrs:
            (import ./examples {inherit evalModules;})
            ({registry = "docker.io/gatehub";} // attrs);
          mkK8STests = attrs:
            (import ./tests {inherit evalModules;})
            ({registry = "docker.io/gatehub";} // attrs);
        in {
          # TODO: access "success" derivation with nice testing utils for nice output
          nginx-example = wasSuccess (mkExamples {}).nginx-deployment.config.testing;
          tests-k8s-1_19 = wasSuccess (mkK8STests {k8sVersion = "1.19";});
          tests-k8s-1_20 = wasSuccess (mkK8STests {k8sVersion = "1.20";});
          tests-k8s-1_21 = wasSuccess (mkK8STests {k8sVersion = "1.21";});
        };
      }
    ))
    // {
      modules = import ./modules;
      overlay = final: prev: {
        kubenix.evalModules = self.evalModules.${prev.system};
        # up to date versions of their nixpkgs equivalents
        kubernetes =
          prev.callPackage ./pkgs/applications/networking/cluster/kubernetes
          {};
        kubectl = prev.callPackage ./pkgs/applications/networking/cluster/kubectl {};
      };
    };
}

{ system ? builtins.currentSystem
, evalModules ? (import ../. { }).evalModules.${system}
}:

{ k8sVersion ? "1.21"
, registry ? throw "Registry url not defined"
, throwError ? true # whether any testing error should throw an error
, enabledTests ? null
}:

let
  config = (evalModules {

    modules = [

      ({ kubenix, ... }: { imports = [ kubenix.modules.testing ]; })

      ({ pkgs, ... }: {
        testing = {
          name = "kubenix-${k8sVersion}";
          throwError = throwError;
          enabledTests = enabledTests;
          tests = [
            ./k8s/simple.nix
            ./k8s/deployment.nix
            #  ./k8s/crd.nix # flaky
            ./k8s/defaults.nix
            ./k8s/order.nix
            ./k8s/submodule.nix
            ./k8s/imports.nix
            # ./helm/simple.nix
            #  ./istio/bookinfo.nix # infinite recursion
            ./submodules/simple.nix
            ./submodules/defaults.nix
            ./submodules/versioning.nix
            ./submodules/exports.nix
            ./submodules/passthru.nix
          ];
          args = {
            images = pkgs.callPackage ./images.nix { };
          };
          docker.registryUrl = registry;
          defaults = [
            {
              features = [ "k8s" ];
              default = {
                kubernetes.version = k8sVersion;
              };
            }
          ];
        };
      })

    ];

  }).config;
in
config.testing // { recurseForDerivations = true; }

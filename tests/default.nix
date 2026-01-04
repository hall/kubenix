{ system ? builtins.currentSystem, evalModules ? (import ../. { }).evalModules.${system} }:
{ k8sVersion ? "1.23"
, registry ? throw "Registry url not defined"
, doThrowError ? true
  # whether any testing error should throw an error
, enabledTests ? null
}:
let
  inherit
    ((evalModules {
      module = { kubenix, pkgs, ... }: {
        imports = [ kubenix.modules.testing ];

        testing = {
          inherit doThrowError enabledTests;
          name = "kubenix-${k8sVersion}";
          tests = [
            ./k8s/simple.nix
            ./k8s/hash-label.nix
            ./k8s/no-hash-label.nix
            ./k8s/deployment.nix
            ./k8s/crd.nix # flaky
            ./k8s/defaults.nix
            ./k8s/order.nix
            ./k8s/submodule.nix
            ./k8s/configmap.nix
            ./k8s/custom-types-switch.nix
            # TODO: `importYaml` uses IFD which fails during `nix flake check` as it evaluates
            # for all systems, not only the current one: https://github.com/hall/kubenix/issues/12
            # ./k8s/imports.nix
            #./helm/simple.nix
            ./istio/bookinfo.nix
            ./submodules/simple.nix
            ./submodules/defaults.nix
            ./submodules/versioning.nix
            ./submodules/exports.nix
            ./submodules/passthru.nix
          ];

          args = { images = pkgs.callPackage ./images.nix { }; };
          docker.registryUrl = registry;

          common = [{
            features = [ "k8s" ];
            options = {
              kubernetes.version = k8sVersion;
            };
          }];
        };
      };
    }))
    config
    ;
in
config.testing // { recurseForDerivations = true; }

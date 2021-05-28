{ pkgs ? import <nixpkgs> { }
, lib ? pkgs.lib
, kubenix ? (import ../. { }).default

, nixosPath ? toString <nixpkgs/nixos>

, k8sVersion ? "1.21"
, registryUrl ? throw "Registry url not defined"
, throwError ? true # whether any testing error should throw an error
, enabledTests ? null
}:

with lib;
let
  images = pkgs.callPackage ./images.nix { };

  config = (kubenix.evalModules {
    modules = [
      kubenix.modules.testing

      {
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
            inherit images;
          };
          docker.registryUrl = registryUrl;
          defaults = [
            {
              features = [ "k8s" ];
              default = {
                kubernetes.version = k8sVersion;
              };
            }
          ];
        };
      }
    ];
    args = {
      inherit pkgs;
    };
    specialArgs = {
      inherit kubenix nixosPath;
    };
  }).config;
in
pkgs.recurseIntoAttrs config.testing

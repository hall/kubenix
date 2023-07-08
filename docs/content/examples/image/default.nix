{ kubenix ? import ../../../.. }:
kubenix.evalModules.${builtins.currentSystem} {
  module = { kubenix, config, pkgs, ... }: {
    imports = with kubenix.modules; [ k8s docker ];
    docker = {
      registry.url = "docker.somewhere.io";
      images.example.image = pkgs.callPackage ./image.nix { };
    };
    kubernetes.resources.pods.example.spec.containers = {
      custom.image = config.docker.images.example.path;
    };
  };
}

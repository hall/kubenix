{
  kubenix ? import ../../../..
, pkgs ? import <nixpkgs> {}
}:
kubenix.evalModules.${builtins.currentSystem} {
  module = {kubenix, ...}: {
    imports = with kubenix.modules; [docker];
    docker.images.example.image = pkgs.callPackage ./image.nix {};
  };
}
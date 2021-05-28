{ lib, pkgs }:

(import ./extra.nix { inherit pkgs lib; }) // {
  k8s = import ./k8s { inherit lib; };
  docker = import ./docker { inherit lib pkgs; };
  helm = import ./helm { inherit pkgs; };
}

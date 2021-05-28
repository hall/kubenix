let
  fetch = import ./lib/compat.nix;
in
{ pkgs ? import (fetch "nixpkgs") { }
, nixosPath ? toString (fetch "nixpkgs") + "/nixos"
, lib ? pkgs.lib
}:

with lib;
let
  kubenixLib = import ./lib { inherit lib pkgs; };
  lib' = lib.extend (lib: self: import ./lib/extra.nix { inherit lib pkgs; });

  defaultSpecialArgs = {
    inherit kubenix nixosPath;
  };

  # evalModules with same interface as lib.evalModules and kubenix as
  # special argument
  evalModules =
    { module ? null
    , modules ? [ module ]
    , specialArgs ? defaultSpecialArgs
    , ...
    }@attrs:
    let
      attrs' = filterAttrs (n: _: n != "module") attrs;
    in
    lib'.evalModules (recursiveUpdate
      {
        inherit specialArgs modules;
        args = {
          inherit pkgs;
          name = "default";
        };
      }
      attrs');

  modules = import ./modules;

  kubenix = {
    inherit evalModules modules;

    lib = kubenixLib;
  };
in
kubenix

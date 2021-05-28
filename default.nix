{ pkgs, lib }:

let

  kubenix = {
    inherit evalModules;
    lib = import ./lib { inherit lib pkgs; };
    modules = import ./modules;
  };

  defaultSpecialArgs = {
    inherit kubenix;
    nixosPath = pkgs.path + "/nixos";
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
      lib' = lib.extend (lib: self: import ./lib/extra.nix { inherit lib pkgs; });
      attrs' = lib.filterAttrs (n: _: n != "module") attrs;
    in
    lib'.evalModules (lib.recursiveUpdate
      {
        inherit specialArgs modules;
        args = {
          inherit pkgs;
          name = "default";
        };
      }
      attrs');
in
kubenix

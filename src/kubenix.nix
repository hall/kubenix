{ pkgs, lib }:

let

  kubenix = {
    inherit evalModules;
    lib = import ./lib { inherit lib pkgs; };
    modules = import ./modules;
  };

  defaultSpecialArgs = {
    inherit kubenix;
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
      lib' = lib.extend (lib: self: import ./lib/upstreamables.nix { inherit lib pkgs; });
      attrs' = builtins.removeAttrs attrs [ "module" ];
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

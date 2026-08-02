# evalModules with same interface as lib.evalModules and kubenix as special argument
{ pkgs }:
let
  evalModules = attrs @ { module ? null, modules ? [ module ], ... }:
    let
      lib' = pkgs.lib.extend (lib: _self: import ./upstreamables.nix { inherit lib pkgs; });
      attrs' = builtins.removeAttrs attrs [ "module" ];
    in
    lib'.evalModules (pkgs.lib.recursiveUpdate
      {
        modules = modules ++ [{
          config._module.args = {
            inherit pkgs;
            name = "default";
          };
        }];
        specialArgs = {
          inherit pkgs;

          kubenix = {
            lib = import ./. { inherit pkgs; inherit (pkgs) lib; };
            inherit evalModules;
            modules = import ../modules;
          };
        };
      }
      attrs');
in
evalModules

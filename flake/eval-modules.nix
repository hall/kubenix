{ inputs, config, ... }:
let
  # evalModules with same interface as lib.evalModules and kubenix as special argument
  mkEvalModules = pkgs:
    let
      evalModules = attrs @ { module ? null, modules ? [ module ], ... }:
        let
          lib' = pkgs.lib.extend (lib: _self: import ../lib/upstreamables.nix { inherit lib pkgs; });
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
                lib = import ../lib { inherit pkgs; inherit (pkgs) lib; };
                inherit evalModules;
                modules = import ../modules;
              };
            };
          }
          attrs');
    in
    evalModules;
in
{
  flake.evalModules = inputs.nixpkgs.lib.genAttrs config.systems (
    system: mkEvalModules inputs.nixpkgs.legacyPackages.${system}
  );

  # Share this system's evalModules with the other perSystem modules.
  perSystem = { system, ... }: {
    _module.args.evalModules = mkEvalModules inputs.nixpkgs.legacyPackages.${system};
  };
}

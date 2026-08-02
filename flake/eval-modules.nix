{ inputs, config, ... }:
let
  # Kept in lib/ so consumers without flake machinery, such as nixpkgs, can import the evaluator
  # directly. The flake only binds it to a package set per system.
  mkEvalModules = pkgs: import ../lib/eval-modules.nix { inherit pkgs; };
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

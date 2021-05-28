{ system ? builtins.currentSystem }:
let
in (
  (import ./lib/compat.nix).flake-compat {
    src = ./.;
    inherit system;
  }
).defaultNix

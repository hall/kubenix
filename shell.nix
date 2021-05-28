{ system ? builtins.currentSystem }:
let
in (
  (import ./compat.nix).flake-compat {
    src = ./.;
    inherit system;
  }
).shellNix

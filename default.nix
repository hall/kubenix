{system ? builtins.currentSystem}: (
    (import ./compat.nix).flake-compat {
      src = ./.;
      inherit system;
    }
  )
  .defaultNix

{ ... }:
{
  # Bound to the package set being extended, so modules evaluated through it see the consumer's
  # nixpkgs. Going via self.evalModules.<system> instead would pin them to kubenix's own.
  flake.overlays.default = final: _prev: {
    kubenix.evalModules = import ../lib/eval-modules.nix { pkgs = final; };
  };
}

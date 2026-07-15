{ self, ... }:
{
  flake.overlays.default = _final: prev: {
    kubenix.evalModules = self.evalModules.${prev.stdenv.hostPlatform.system};
  };
}

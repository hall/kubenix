{ kubenix ? import ../../../.. }:
kubenix.evalModules.${builtins.currentSystem} {
  module = { kubenix, ... }: {
    imports = [ ./module.nix ];

    kubenix.project = "multi-namespace-example";
    kubernetes.version = "1.24";
  };
}

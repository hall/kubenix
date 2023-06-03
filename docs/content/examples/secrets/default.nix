{ kubenix ? import ../../../.. }:
kubenix.evalModules.${builtins.currentSystem} {
  module = { kubenix, ... }: {
    imports = [ kubenix.modules.k8s ];
    kubernetes.resources.secrets.example.stringData = {
      password = "ref+file:///path/to/secret";
    };
  };
}

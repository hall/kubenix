{ kubenix ? import ../../../.. }:
kubenix.evalModules.${builtins.currentSystem} {
  module = { kubenix, ... }: {
    imports = [ kubenix.modules.testing ];
    testing = {
      tests = [ ./test.nix ];
      common = [{
        features = [ "k8s" ];
        options = {
          kubernetes.version = "1.24";
        };
      }];
    };
  };
}

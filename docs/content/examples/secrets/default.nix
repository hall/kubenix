{kubenix ? import ../../../..}:
kubenix.evalModules.x86_64-linux {
  module = {kubenix, ...}: {
    imports = with kubenix; [k8s];
    kubernetes.resources.secrets.example.stringData = {
      password = "ref+file:///path/to/secret";
    };
  };
}

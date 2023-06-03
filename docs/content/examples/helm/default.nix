{kubenix ? import ../../../..}:
kubenix.evalModules.${builtins.currentSystem} {
  module = {kubenix, ...}: {
    imports = [kubenix.modules.helm];
    kubernetes.helm.releases.example = {
      chart = kubenix.lib.helm.fetch {
        repo = "https://charts.bitnami.com/bitnami";
        chart = "nginx";
        version = "15.0.1";
        sha256 = "sKVqx99O4SNIq5y8Qo/b/2xIqXqSsZJzrgnYYz/0TKg=";
      };
      # arbitrary attrset passed as values to the helm release
      values.replicaCount = 2;
    };
  };
}

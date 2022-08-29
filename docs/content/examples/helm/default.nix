{kubenix ? import ../../../..}:
kubenix.evalModules.${builtins.currentSystem} {
  module = {kubenix, ...}: {
    imports = with kubenix.modules; [helm];
    kubernetes.helm.releases.example = {
      chart = kubenix.lib.helm.fetch {
        chart = "nginx";
        repo = "https://charts.bitnami.com/bitnami";
        sha256 = "sha256-wP3tcBnySx+kvZqfW2W9k665oi8KOI50tCcAl0g9cuw=";
      };
      values = {
        replicaCount = 2;
      };
    };
  };
}

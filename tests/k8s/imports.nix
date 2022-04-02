{
  config,
  lib,
  kubenix,
  ...
}:
with lib; let
  pod = config.kubernetes.api.resources.core.v1.Pod.test;
  deployment = config.kubernetes.api.resources.apps.v1.Deployment.nginx-deployment;
in {
  imports = with kubenix.modules; [test k8s];

  test = {
    name = "k8s-imports";
    description = "Simple k8s testing imports";
    enable = builtins.compareVersions config.kubernetes.version "1.10" >= 0;
    assertions = [
      {
        message = "Pod should have name set";
        assertion = pod.metadata.name == "test";
      }
      {
        message = "Deployment should have name set";
        assertion = deployment.metadata.name == "nginx-deployment";
      }
    ];
  };

  kubernetes.imports = [
    ./pod.json
    ./deployment.yaml
  ];
}

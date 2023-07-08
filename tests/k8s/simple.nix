{ config, kubenix, ... }:
let
  cfg = config.kubernetes.api.resources.pods.nginx;
in
{
  imports = [ kubenix.modules.test kubenix.modules.k8s ];

  test = {
    name = "k8s-simple";
    description = "Simple k8s testing wheter name, apiVersion and kind are preset";
    assertions = [
      {
        message = "should have apiVersion and kind set";
        assertion = cfg.apiVersion == "v1" && cfg.kind == "Pod";
      }
      {
        message = "should have name set";
        assertion = cfg.metadata.name == "nginx";
      }
    ];
  };

  kubernetes.resources.pods.nginx = { };
}

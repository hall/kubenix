{ config, lib, kubenix, ... }:
with lib; let
  inherit (config.kubernetes.api.resources.pods) pod1;
  inherit (config.kubernetes.api.resources.pods) pod2;
  inherit (config.kubernetes.api.resources.pods) pod3;
in
{
  imports = with kubenix.modules; [ test k8s ];

  test = {
    name = "k8s-defaults";
    description = "Simple k8s testing wheter name, apiVersion and kind are preset";
    assertions = [
      {
        message = "Should have label set with resource";
        assertion = pod1.metadata.labels.resource-label == "value";
      }
      {
        message = "Should have default label set with group, version, kind";
        assertion = pod1.metadata.labels.gvk-label == "value";
      }
      {
        message = "Should have conditional annotation set";
        assertion = pod2.metadata.annotations.conditional-annotation == "value";
      }
      {
        message = "Should have protocol UDP";
        assertion = (elemAt (head pod3.spec.containers).ports 1).protocol == "UDP";
      }
    ];
  };

  kubernetes.resources.pods.pod1 = { };

  kubernetes.resources.pods.pod2 = {
    metadata.labels.custom-label = "value";
  };

  kubernetes.resources.pods.pod3 = {
    spec.containers.container1.ports = [
      {
        containerPort = 80;
      }
      {
        containerPort = 80;
        protocol = "UDP";
      }
    ];
  };

  kubernetes.api.defaults = [
    {
      resource = "pods";
      default.metadata.labels.resource-label = "value";
    }
    {
      group = "core";
      kind = "Pod";
      version = "v1";
      default.metadata.labels.gvk-label = "value";
    }
    {
      resource = "pods";
      default = { config, ... }: {
        config.metadata.annotations = mkIf (config.metadata.labels ? "custom-label") {
          conditional-annotation = "value";
        };
      };
    }
  ];
}

{
  config,
  lib,
  kubenix,
  pkgs,
  ...
}:
with lib; let
  cfg = config.kubernetes.api.resources.customResourceDefinitions.crontabs;
in {
  imports = with kubenix.modules; [test k8s];

  test = {
    name = "k8s-order";
    description = "test tesing k8s resource order";
    assertions = [
      {
        message = "should have correct order of resources";
        assertion =
          (elemAt config.kubernetes.objects 0).kind
          == "CustomResourceDefinition"
          && (elemAt config.kubernetes.objects 1).kind == "Namespace"
          && (elemAt config.kubernetes.objects 2).kind == "CronTab";
      }
    ];
  };

  kubernetes.resources.customResourceDefinitions.crontabs = {
    apiVersion = "apiextensions.k8s.io/v1";
    metadata.name = "crontabs.stable.example.com";
    spec = {
      group = "stable.example.com";
      versions = [
        {
          name = "v1";
          served = true;
          schema = true;
        }
      ];
      scope = "Namespaced";
      names = {
        plural = "crontabs";
        singular = "crontab";
        kind = "CronTab";
        shortNames = ["ct"];
      };
    };
  };

  kubernetes.customTypes = [
    {
      name = "crontabs";
      description = "CronTabs resources";

      attrName = "cronTabs";
      group = "stable.example.com";
      version = "v1";
      kind = "CronTab";
      module = {
        options.schedule = mkOption {
          description = "Crontab schedule script";
          type = types.str;
        };
      };
    }
  ];

  kubernetes.resources.namespaces.test = {};

  kubernetes.resources."stable.example.com"."v1".CronTab.crontab.spec.schedule = "* * * * *";
}

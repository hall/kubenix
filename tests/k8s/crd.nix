{ config, lib, kubenix, ... }:
with lib; let
  latestCrontab = config.kubernetes.api.resources.cronTabs.latest;
in
{
  imports = with kubenix.modules; [ test k8s ];

  test = {
    name = "k8s-crd";
    description = "Simple test testing CRD";
    enable = builtins.compareVersions config.kubernetes.version "1.8" >= 0;
    assertions = [{
      message = "Custom resource should have correct version set";
      assertion = latestCrontab.apiVersion == "stable.example.com/v2";
    }];
    script = ''
      @pytest.mark.applymanifest('${config.kubernetes.resultYAML}')
      def test_testing_module(kube):
          """Tests whether deployment gets successfully created"""

          kube.wait_for_registered(timeout=30)

          kube.get_crds()
          crds = kube.get_crds()
          crontabs_crd = crds.get('crontabs')
          assert crontabs_crd is not None

          # TODO: verify
          # kubectl get crontabs | grep -i versioned
          crontabs_crd_versioned = crontabs_crd.get('versioned')
          assert crontabs_crd_versioned is not None
          # kubectl get crontabs | grep -i latest
          crontabs_crd_latest = crontabs_crd.get('latest')
          assert crontabs_crd_latest is not None
    '';
  };

  kubernetes.customTypes = [
    {
      group = "stable.example.com";
      version = "v1";
      kind = "CronTab";
      attrName = "cronTabs";
      description = "CronTabs resources";
      module = {
        options.schedule = mkOption {
          description = "Crontab schedule script";
          type = types.str;
        };
      };
    }
    {
      group = "stable.example.com";
      version = "v2";
      kind = "CronTab";
      description = "CronTabs resources";
      attrName = "cronTabs";
      module = {
        options = {
          schedule = mkOption {
            description = "Crontab schedule script";
            type = types.str;
          };

          command = mkOption {
            description = "Command to run";
            type = types.str;
          };
        };
      };
    }
    {
      group = "stable.example.com";
      version = "v3";
      kind = "CronTab";
      description = "CronTabs resources";
      attrName = "cronTabsV3";
      module = {
        options = {
          schedule = mkOption {
            description = "Crontab schedule script";
            type = types.str;
          };

          command = mkOption {
            description = "Command to run";
            type = types.str;
          };
        };
      };
    }
  ];

  kubernetes.resources."stable.example.com"."v1".CronTab.versioned.spec.schedule = "* * * * *";
  kubernetes.resources.cronTabs.latest.spec.schedule = "* * * * *";
  kubernetes.resources.cronTabsV3.latest.spec.schedule = "* * * * *";
}

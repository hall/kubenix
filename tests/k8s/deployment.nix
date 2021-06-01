{ config, lib, pkgs, kubenix, images, test, ... }:

with lib;
let
  cfg = config.kubernetes.api.resources.deployments.nginx;
  image = images.nginx;

  clientPod = builtins.toFile "client.json" (builtins.toJSON {
    apiVersion = "v1";
    kind = "Pod";
    metadata = {
      namespace = config.kubernetes.namespace;
      name = "curl";
    };
    spec.containers = [{
      name = "curl";
      image = config.docker.images.curl.path;
      args = [ "curl" "--retry" "20" "--retry-connrefused" "http://nginx" ];
    }];
    spec.restartPolicy = "Never";
  });

in
{
  imports = [ kubenix.modules.test kubenix.modules.k8s kubenix.modules.docker ];

  test = {
    name = "k8s-deployment";
    description = "Simple k8s testing a simple deployment";
    assertions = [{
      message = "should have correct apiVersion and kind set";
      assertion =
        if ((builtins.compareVersions config.kubernetes.version "1.7") <= 0)
        then cfg.apiVersion == "apps/v1beta1"
        else if ((builtins.compareVersions config.kubernetes.version "1.8") <= 0)
        then cfg.apiVersion == "apps/v1beta2"
        else cfg.apiVersion == "apps/v1";
    }
      {
        message = "should have corrent kind set";
        assertion = cfg.kind == "Deployment";
      }
      {
        message = "should have replicas set";
        assertion = cfg.spec.replicas == 3;
      }];
    script = ''
      import time

      @pytest.mark.applymanifest('${test.kubernetes.resultYAML}')
      def test_deployment(kube):
          """Tests whether deployment gets successfully created"""

          kube.wait_for_registered(timeout=30)

          deployments = kube.get_deployments()
          nginx_deploy = deployments.get('nginx')
          assert nginx_deploy is not None

          pods = nginx_deploy.get_pods()
          assert len(pods) == 3

          client_pod = kube.load_pod('${clientPod}')
          client_pod.create()

          client_pod.wait_until_ready(timeout=30)
          client_pod.wait_until_containers_start()

          container = client_pod.get_container('curl')

          time.sleep(5)

          logs = container.get_logs()

          assert "Hello from NGINX" in logs
    '';
  };

  docker.images = {
    nginx.image = image;
    curl.image = images.curl;
  };

  kubernetes.resources.deployments.nginx = {
    spec = {
      replicas = 3;
      selector.matchLabels.app = "nginx";
      template.metadata.labels.app = "nginx";
      template.spec = {
        containers.nginx = {
          image = config.docker.images.nginx.path;
          imagePullPolicy = "IfNotPresent";
        };
      };
    };
  };

  kubernetes.resources.services.nginx = {
    spec = {
      ports = [{
        name = "http";
        port = 80;
      }];
      selector.app = "nginx";
    };
  };
}

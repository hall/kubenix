{ images
, evalModules
, pkgs
, ...
}:
let
  inherit (module.config.docker) copyScript;
  module = evalModules {
    modules = [
      ({ kubenix, ... }: {
        imports = [ kubenix.modules.docker ];
        docker = {
          registry.host = "registry1:5000";

          # Curl 1 image just uses defaults
          images.curl1.image = images.curl;

          # Curl 2 image uses runtime variables
          images.curl2 = {
            image = images.curl;
            name = "ref+envsubst://$CURL2_PREFIX+curlref+envsubst://$CURL2_SUFFIX+";
            registry.host = "registryref+envsubst://$CURL2_REG+:5000";
            tag = "ref+envsubst://$CURL2_TAG";
          };

          # Nginx image is customized
          images.nginx = {
            image = images.nginx;
            name = "custom-nginx";
            registry.host = "registry2:5000";
            tag = "nightly";
          };
        };
      })
    ];
  };

  registryModule = {
    services.dockerRegistry = {
      enable = true;
      listenAddress = "0.0.0.0";
      openFirewall = true;
    };
  };
in
pkgs.testers.runNixOSTest {
  name = "docker-multiple-registries";
  nodes = {
    registry1 = registryModule;
    registry2 = registryModule;

    client = {
      environment.systemPackages = [
        copyScript
        pkgs.skopeo
      ];
      environment.variables = {
        CURL2_PREFIX = "kubenix-";
        CURL2_SUFFIX = "2";
        CURL2_REG = "2";
        CURL2_TAG = "now";
      };
    };
  };

  testScript = ''
    start_all()

    registry1.wait_for_unit("docker-registry.service")
    registry2.wait_for_unit("docker-registry.service")

    # All images missing
    client.fail("skopeo inspect --tls-verify=false docker://registry1:5000/curl:latest")
    client.fail("skopeo inspect --tls-verify=false docker://registry2:5000/curl:latest")
    client.fail("skopeo inspect --tls-verify=false docker://registry1:5000/kubenix-curl2:now")
    client.fail("skopeo inspect --tls-verify=false docker://registry2:5000/kubenix-curl2:now")
    client.fail("skopeo inspect --tls-verify=false docker://registry1:5000/custom-nginx:nightly")
    client.fail("skopeo inspect --tls-verify=false docker://registry2:5000/custom-nginx:nightly")

    # Push them
    client.succeed("kubenix-push-images --insecure-policy --dest-tls-verify=false")

    # All images present where they should
    client.succeed("skopeo inspect --tls-verify=false docker://registry1:5000/curl:latest")
    client.fail("skopeo inspect --tls-verify=false docker://registry2:5000/curl:latest")
    client.fail("skopeo inspect --tls-verify=false docker://registry1:5000/kubenix-curl2:now")
    client.succeed("skopeo inspect --tls-verify=false docker://registry2:5000/kubenix-curl2:now")
    client.fail("skopeo inspect --tls-verify=false docker://registry1:5000/custom-nginx:nightly")
    client.succeed("skopeo inspect --tls-verify=false docker://registry2:5000/custom-nginx:nightly")
  '';
}

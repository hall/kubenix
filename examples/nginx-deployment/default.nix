{ evalModules, registry }:

let
  # evaluated configuration
  config = (evalModules {
    module =
      { kubenix, ... }: {
        imports = [
          kubenix.modules.testing
          ./module.nix
        ];

        # commonalities
        kubenix.project = "nginx-deployment-example";
        docker.registry.url = registry;
        kubernetes.version = "1.21";

        testing = {
          tests = [ ./test.nix ];
          docker.registryUrl = "";
          # testing commonalities for tests that exhibit the respective feature
          defaults = [
            {
              features = [ "k8s" ];
              default = {
                kubernetes.version = "1.20";
              };
            }
          ];
        };
      };
  }).config;

in
{
  inherit config;

  # config checks
  checks = config.testing.success;

  # TODO: e2e test
  # test = config.testing.result;

  # nixos test script for running the test
  test-script = config.testing.testsByName.nginx-deployment.script;

  # genreated kubernetes List object
  generated = config.kubernetes.generated;

  # JSON file you can deploy to kubernetes
  result = config.kubernetes.result;

  # Exported docker images
  images = config.docker.export;

  # script to push docker images to registry
  pushDockerImages = config.docker.copyScript;
}

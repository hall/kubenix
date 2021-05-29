{ evalModules, registry }:

let
  # evaluated configuration
  config = (evalModules {
    modules = [

      ({ kubenix, ... }: { imports = [ kubenix.modules.testing ]; })

      ./module.nix

      { docker.registry.url = registry; }

      {
        testing.tests = [ ./test.nix ];
        testing.docker.registryUrl = "";
      }

    ];
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

{
  name,
  config,
  lib,
  kubenix,
  images,
  ...
}:
with lib; let
  cfg = config.submodules.instances.passthru;
in {
  imports = with kubenix.modules; [test submodules k8s docker];

  test = {
    name = "k8s-submodule";
    description = "Simple k8s submodule test";
    assertions = [
      {
        message = "Submodule has correct name set";
        assertion = (head config.kubernetes.objects).metadata.name == "passthru";
      }
      {
        message = "Should expose docker image";
        assertion = (head config.docker.export).imageName == "xtruder/nginx";
      }
    ];
  };

  kubernetes.namespace = "test-namespace";

  submodules.imports = [
    {
      module = {
        name,
        config,
        ...
      }: {
        imports = with kubenix.modules; [submodule k8s docker];

        config = {
          submodule = {
            name = "test-submodule";
            passthru = {
              kubernetes.objects = config.kubernetes.objects;
              docker.images = config.docker.images;
            };
          };

          kubernetes.resources.pods.nginx = {
            metadata.name = name;
            spec.containers.nginx.image = config.docker.images.nginx.path;
          };

          docker.images.nginx.image = images.nginx;
        };
      };
    }
  ];

  kubernetes.api.defaults = [
    {
      propagate = true;
      default.metadata.labels.my-label = "my-value";
    }
  ];

  submodules.instances.passthru = {
    submodule = "test-submodule";
  };

  submodules.instances.no-passthru = {
    submodule = "test-submodule";
    passthru.enable = false;
  };
}

{ config
, lib
, kubenix
, ...
}:
with lib; {
  imports = with kubenix.modules; [ test submodules k8s docker ];

  test = {
    name = "k8s-module-instance-label";
    description = "Test that module instance name is added as label";
    assertions = [
      {
        message = "Should have kubenix/module-instance label";
        assertion = (head config.kubernetes.objects).metadata.labels."kubenix/module-instance" == "test-instance";
      }
      {
        message = "Should have kubenix/module-name label";
        assertion = (head config.kubernetes.objects).metadata.labels."kubenix/module-name" == "simple-module";
      }
    ];
  };

  kubernetes.namespace = "test-namespace";

  submodules.imports = [
    {
      module =
        { name
        , config
        , ...
        }: {
          imports = with kubenix.modules; [ submodule k8s ];

          config = {
            submodule = {
              name = "simple-module";
              passthru.kubernetes.objects = config.kubernetes.objects;
            };

            kubernetes.resources.configMaps.test-config = {
              metadata.name = name;
              data.key = "value";
            };
          };
        };
    }
  ];

  submodules.instances.test-instance = {
    submodule = "simple-module";
  };
}

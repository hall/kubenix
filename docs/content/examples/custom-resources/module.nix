{ kubenix, config, lib, ... }: {
  imports = [ kubenix.modules.k8s ];

  # 1. Define the Custom Resource Definition (CRD)
  # This tells Kubenix about the new resource type so it can generate options for it.
  kubernetes.customTypes = [{
    group = "stable.example.com";
    version = "v1";
    kind = "CronTab";
    # The attribute name to use under `kubernetes.resources`
    attrName = "crontabs";
    # Define the schema of the custom resource using Nix options
    module = {
      options = {
        cronSpec = lib.mkOption {
          description = "Cron schedule";
          type = lib.types.str;
        };
        image = lib.mkOption {
          description = "Image to run";
          type = lib.types.str;
        };
        replicas = lib.mkOption {
          description = "Number of replicas";
          type = lib.types.int;
          default = 1;
        };
      };
    };
  }];

  # 2. Instantiate the Custom Resource
  # Now we can use the `crontabs` attribute to define resources.
  kubernetes.resources.crontabs.my-new-cron-object = {
    metadata.name = "my-new-cron-object";
    spec.cronSpec = "* * * * */5";
    spec.image = "my-awesome-cron-image";
  };
}

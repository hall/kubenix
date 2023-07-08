{ config, lib, pkgs, kubenix, ... }: {
  imports = with kubenix.modules; [ submodules k8s ];

  # Import submodule.
  submodules.imports = [
    ./namespaced.nix
  ];

  # We can now create multiple submodule instances.
  submodules.instances.namespace-http = {
    #                  ~~~~~~~~~~~~~~
    #                          ^
    #  ╭-----------------------╯
    # The submodule instance name is injected as the name attribute to
    # the submodule function. In this example, it is used as the namespace
    # name.
    #
    # This needs to match config.submodule.name of an imported submodule.
    submodule = "namespaced";
    # Now we can set the args options defined in the submodule.
    args.kubernetes.resources = {
      services.nginx.spec = {
        ports = [{
          name = "http";
          port = 80;
        }];
        selector.app = "nginx";
      };
    };
  };

  submodules.instances.namespace-https = {
    submodule = "namespaced";
    args.kubernetes.resources = {
      services.nginx.spec = {
        ports = [{
          name = "https";
          port = 443;
        }];
        selector.app = "nginx";
      };
    };
    # Example of how other defaults can be applied to resources
    # within a submodule.
    args.kubernetes.version = "1.26";
  };

  # Resources defined in parent context use namespace set at this
  # level and are not affected by the above submodules.
  kubernetes.namespace = "default";
  kubernetes.resources.services.nginx.spec = {
    selector.app = "nginx-default";
  };
}

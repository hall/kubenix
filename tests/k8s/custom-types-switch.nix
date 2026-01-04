{ config, lib, kubenix, ... }:
with lib;
{
  imports = with kubenix.modules; [ k8s ];

  test = {
    name = "customTypesModuleDefinesCRDSpec";
    description = "Test customTypesModuleDefinesCRDSpec = false";
    assertions = [{
      message = "Custom resource should have correct version set";
      assertion = lib.removeAttrs config.kubernetes.api.resources.flexibleResource.test [ "metadata" ] == {
        apiVersion = "example.com/v1";
        kind = "FlexibleResource";
        spec.foo = "bar";
        status = "active";
      };
    }];
  };

  kubernetes.customTypesModuleDefinesCRDSpec = false;

  kubernetes.customTypes = [
    {
      group = "example.com";
      version = "v1";
      kind = "FlexibleResource";
      attrName = "flexibleResource";
      module = {
        options.spec = mkOption {
          type = types.attrs;
          default = { };
        };
        options.status = mkOption {
          type = types.str;
          default = "";
        };
      };
    }
  ];

  kubernetes.resources.flexibleResource.test = {
    spec.foo = "bar";
    status = "active";
  };
}

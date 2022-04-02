{
  name,
  config,
  lib,
  kubenix,
  ...
}:
with lib; let
  cfg = config.submodules.instances.instance;
  args = cfg.config.submodule.args;
in {
  imports = with kubenix.modules; [test submodules];

  test = {
    name = "submodules-simple";
    description = "Simple k8s submodule test";
    assertions = [
      {
        message = "Submodule name is set";
        assertion = cfg.name == "instance";
      }
      {
        message = "Submodule version is set";
        assertion = cfg.version == null;
      }
      {
        message = "Submodule config has submodule definition";
        assertion = cfg.config.submodule.name == "submodule";
      }
      {
        message = "Should have argument set";
        assertion = args.value == "test";
      }
      {
        message = "Should have submodule name set";
        assertion = args.name == "instance";
      }
      {
        message = "should have tag set";
        assertion = elem "tag" (cfg.config.submodule.tags);
      }
    ];
  };

  submodules.propagate.enable = true;
  submodules.imports = [
    {
      module = {submodule, ...}: {
        imports = [kubenix.modules.submodule];

        options.submodule.args = {
          name = mkOption {
            description = "Submodule name";
            type = types.str;
            default = submodule.name;
          };
          value = mkOption {
            description = "Submodule argument";
            type = types.str;
          };
        };

        config = {
          submodule.name = "submodule";
          submodule.tags = ["tag"];
        };
      };
    }
  ];

  submodules.instances.instance = {
    submodule = "submodule";
    args = {
      value = "test";
    };
  };
}

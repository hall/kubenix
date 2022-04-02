{
  name,
  config,
  lib,
  kubenix,
  ...
}:
with lib; let
  inst-exact = config.submodules.instances.inst-exact.config;
  inst-regex = config.submodules.instances.inst-regex.config;
  inst-latest = config.submodules.instances.inst-latest.config;

  submodule = {
    imports = [kubenix.modules.submodule];

    options.version = mkOption {
      type = types.str;
      default = "undefined";
    };

    config.submodule.name = "subm";
  };
in {
  imports = with kubenix.modules; [test submodules];

  test = {
    name = "submodules-versioning";
    description = "Submodules versioning test";
    assertions = [
      {
        message = "should select exact version";
        assertion = inst-exact.version == "1.1.0";
      }
      {
        message = "should select regex version";
        assertion = inst-regex.version == "1.2.1";
      }
      {
        message = "should select latest version";
        assertion = inst-latest.version == "1.2.1";
      }
    ];
  };

  submodules.imports = [
    {
      modules = [
        {
          config.submodule.version = "1.0.0";
          config.version = "1.0.0";
        }
        submodule
      ];
    }
    {
      modules = [
        {
          config.submodule.version = "1.1.0";
          config.version = "1.1.0";
        }
        submodule
      ];
    }
    {
      modules = [
        {
          config.submodule.version = "1.2.0";
          config.version = "1.2.0";
        }
        submodule
      ];
    }
    {
      modules = [
        {
          config.submodule.version = "1.2.1";
          config.version = "1.2.1";
        }
        submodule
      ];
    }
  ];

  submodules.instances.inst-exact = {
    submodule = "subm";
    version = "1.1.0";
  };

  submodules.instances.inst-regex = {
    submodule = "subm";
    version = "~1.2.*";
  };

  submodules.instances.inst-latest.submodule = "subm";
}

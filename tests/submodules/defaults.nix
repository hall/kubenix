{
  name,
  config,
  lib,
  kubenix,
  ...
}:
with lib; let
  instance1 = config.submodules.instances.instance1;
  instance2 = config.submodules.instances.instance2;
  instance3 = config.submodules.instances.instance3;
  instance4 = config.submodules.instances.instance4;
  instance5 = config.submodules.instances.instance5;
  versioned-submodule = config.submodules.instances.versioned-submodule;

  submodule = {name, ...}: {
    imports = [kubenix.modules.submodule];

    options.submodule.args = {
      value = mkOption {
        description = "Submodule value";
        type = types.str;
      };

      defaultValue = mkOption {
        description = "Submodule default value";
        type = types.str;
      };
    };
  };
in {
  imports = with kubenix.modules; [test submodules];

  test = {
    name = "submodules-defaults";
    description = "Simple submodule test";
    assertions = [
      {
        message = "should apply defaults by tag1";
        assertion = instance1.config.submodule.args.value == "value1";
      }
      {
        message = "should apply defaults by tag2";
        assertion = instance2.config.submodule.args.value == "value2";
      }
      {
        message = "should apply defaults by tag2";
        assertion = instance3.config.submodule.args.value == "value2";
      }
      {
        message = "should apply defaults to all";
        assertion =
          instance1.config.submodule.args.defaultValue
          == "value"
          && instance2.config.submodule.args.defaultValue == "value";
      }
      {
        message = "instance1 and instance3 should have value of default-value";
        assertion = instance3.config.submodule.args.defaultValue == "default-value";
      }
      {
        message = "should apply defaults by submodule name";
        assertion = instance4.config.submodule.args.value == "value4";
      }
      {
        message = "should apply defaults by custom condition";
        assertion = instance5.config.submodule.args.defaultValue == "my-custom-value";
      }
      {
        message = "should apply defaults to versioned submodule";
        assertion = versioned-submodule.config.submodule.args.defaultValue == "versioned-submodule";
      }
    ];
  };

  submodules.imports = [
    {
      modules = [
        submodule
        {
          submodule = {
            name = "submodule1";
            tags = ["tag1"];
          };
        }
      ];
    }
    {
      modules = [
        submodule
        {
          submodule = {
            name = "submodule2";
            tags = ["tag2"];
          };
        }
      ];
    }
    {
      modules = [
        submodule
        {
          submodule = {
            name = "submodule3";
            tags = ["tag2"];
          };
        }
      ];
    }
    {
      modules = [
        submodule
        {
          submodule = {
            name = "submodule4";
          };
        }
      ];
    }
    {
      modules = [
        submodule
        {
          submodule = {
            name = "submodule5";
          };
          submodule.args.value = "custom-value";
        }
      ];
    }
    {
      modules = [
        submodule
        {
          submodule = {
            name = "versioned-submodule";
            version = "2.0.0";
          };
        }
      ];
    }
  ];

  submodules.defaults = [
    {
      default.submodule.args.defaultValue = mkDefault "value";
    }
    {
      tags = ["tag1"];
      default.submodule.args.value = mkDefault "value1";
    }
    {
      tags = ["tag2"];
      default.submodule.args.value = mkDefault "value2";
    }
    {
      name = "submodule4";
      default.submodule.args.value = mkDefault "value4";
    }
    {
      default = {config, ...}: {
        submodule.args.defaultValue = mkIf (config.submodule.args.value == "custom-value") "my-custom-value";
      };
    }
    {
      name = "versioned-submodule";
      version = "2.0.0";
      default.submodule.args.value = mkDefault "versioned";
    }
  ];

  submodules.instances.instance1.submodule = "submodule1";
  submodules.instances.instance2.submodule = "submodule2";
  submodules.instances.instance3 = {
    submodule = "submodule3";
    args.defaultValue = "default-value";
  };
  submodules.instances.instance4.submodule = "submodule4";
  submodules.instances.instance5.submodule = "submodule5";
  submodules.instances.versioned-submodule = {
    submodule = "versioned-submodule";
    args.defaultValue = "versioned-submodule";
  };
}

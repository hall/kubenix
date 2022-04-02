{
  name,
  config,
  lib,
  kubenix,
  ...
}:
with lib; let
  submodule = {name, ...}: {
    imports = [kubenix.modules.submodule];

    config.submodule = {
      name = "subm";
      passthru.global.${name} = "true";
    };
  };
in {
  imports = with kubenix.modules; [test submodules];

  options = {
    global = mkOption {
      description = "Global value";
      type = types.attrs;
      default = {};
    };
  };

  config = {
    test = {
      name = "submodules-passthru";
      description = "Submodules passthru test";
      assertions = [
        {
          message = "should passthru values if passthru enabled";
          assertion = hasAttr "inst1" config.global && config.global.inst1 == "true";
        }
        {
          message = "should not passthru values if passthru not enabled";
          assertion = !(hasAttr "inst2" config.global);
        }
        {
          message = "should passthru by default";
          assertion = hasAttr "inst3" config.global && config.global.inst3 == "true";
        }
      ];
    };

    submodules.imports = [
      {
        modules = [submodule];
      }
    ];

    submodules.instances.inst1 = {
      submodule = "subm";
      passthru.enable = true;
    };

    submodules.instances.inst2 = {
      submodule = "subm";
      passthru.enable = false;
    };

    submodules.instances.inst3 = {
      submodule = "subm";
    };
  };
}

{
  config,
  lib,
  ...
}:
with lib; {
  imports = [./base.nix];

  options.submodule = {
    name = mkOption {
      description = "Module name";
      type = types.str;
    };

    description = mkOption {
      description = "Module description";
      type = types.str;
      default = "";
    };

    version = mkOption {
      description = "Module version";
      type = types.str;
      default = "1.0.0";
    };

    tags = mkOption {
      description = "List of submodule tags";
      type = types.listOf types.str;
      default = [];
    };

    exports = mkOption {
      description = "Attribute set of functions to export";
      type = types.attrs;
      default = {};
    };

    passthru = mkOption {
      description = "Attribute set to passthru";
      type = types.attrs;
      default = {};
    };

    args._empty = mkOption {};
  };

  config._module.args.args = config.submodule.args;
  config._m.features = ["submodule"];
}

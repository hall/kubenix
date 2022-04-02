{
  config,
  lib,
  ...
}:
with lib; {
  options = {
    kubenix.project = mkOption {
      description = "Name of the project";
      type = types.str;
      default = "kubenix";
    };

    _m.features = mkOption {
      description = "List of features exposed by module";
      type = types.listOf types.str;
      default = [];
    };

    _m.propagate = mkOption {
      description = "Module propagation options";
      type = types.listOf (types.submodule ({config, ...}: {
        options = {
          features = mkOption {
            description = "List of features that submodule has to have to propagate module";
            type = types.listOf types.str;
            default = [];
          };

          module = mkOption {
            description = "Module to propagate";
            type = types.unspecified;
            default = {};
          };
        };
      }));
      default = [];
    };
  };
}

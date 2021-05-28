{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.test;

in
{
  options.test = {
    name = mkOption {
      description = "Test name";
      type = types.str;
    };

    description = mkOption {
      description = "Test description";
      type = types.str;
    };

    enable = mkOption {
      description = "Whether to enable test";
      type = types.bool;
      default = true;
    };

    assertions = mkOption {
      type = types.listOf (types.submodule {
        options = {
          assertion = mkOption {
            description = "assertion value";
            type = types.bool;
            default = false;
          };

          message = mkOption {
            description = "assertion message";
            type = types.str;
          };
        };
      });
      default = [ ];
      example = [{ assertion = false; message = "you can't enable this for some reason"; }];
      description = ''
        This option allows modules to express conditions that must
        hold for the evaluation of the system configuration to
        succeed, along with associated error messages for the user.
      '';
    };

    script = mkOption {
      description = "Test script to use for e2e test";
      type = types.nullOr (types.either types.lines types.path);
      default = null;
    };

  };
}

{ config, pkgs, lib, kubenix, ... }:

with lib;
let
  cfg = config.testing;

  testModule = {
    imports = [ ./evalTest.nix ];

    # passthru testing configuration
    config._module.args = {
      inherit pkgs kubenix;
      testing = cfg;
    };
  };

  isTestEnabled = test:
    (cfg.enabledTests == null || elem test.name cfg.enabledTests) && test.enable;

in
{
  imports = [
    ./docker.nix
    ./driver/kubetest.nix
    ./runtime/local.nix
    ./runtime/nixos-k8s.nix
  ];

  options.testing = {
    name = mkOption {
      description = "Testing suite name";
      type = types.str;
      default = "default";
    };

    throwError = mkOption {
      description = "Whether to throw error";
      type = types.bool;
      default = true;
    };

    common = mkOption {
      description = "List of common options to apply to tests";
      type = types.listOf (types.submodule ({ config, ... }: {
        options = {
          features = mkOption {
            description = "List of features that test has to have to apply options";
            type = types.listOf types.str;
            default = [ ];
          };

          options = mkOption {
            description = "Options to apply to test";
            type = types.unspecified;
            default = { };
            apply = default: { _file = "testing.common"; } // default;
          };
        };
      }));
      default = [ ];
    };

    tests = mkOption {
      description = "List of test cases";
      default = [ ];
      type = types.listOf (types.coercedTo types.path
        (module: {
          inherit module;
        })
        (types.submodule testModule));
      apply = tests: filter isTestEnabled tests;
    };

    testsByName = mkOption {
      description = "Tests by name";
      type = types.attrsOf types.attrs;
      default = listToAttrs (map (test: nameValuePair test.name test) cfg.tests);
    };

    enabledTests = mkOption {
      description = "List of enabled tests (by default all tests are enabled)";
      type = types.nullOr (types.listOf types.str);
      default = null;
    };

    args = mkOption {
      description = "Attribute set of extra args passed to tests";
      type = types.attrs;
      default = { };
    };

    success = mkOption {
      internal = true; # read only property
      description = "Whether testing was a success";
      type = types.bool;
      default = all (test: test.success) cfg.tests;
    };

    testScript = mkOption {
      internal = true; # set by test driver
      type = types.package;
      description = "Script to run e2e tests";
    };
  };
}

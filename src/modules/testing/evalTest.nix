{ lib, config, testing, kubenix, ... }:

with lib;
let
  modules = [
    # testing module
    config.module

    ./test-options.nix
    ../base.nix

    # passthru some options to test
    {
      config = {
        kubenix.project = mkDefault config.name;
        _module.args = {
          inherit kubenix;
          test = config;
        } // testing.args;
      };
    }
  ];

  # eval without checking
  evaled' = kubenix.evalModules {
    check = false;
    inherit modules;
  };

  # test configuration
  testConfig = evaled'.config.test;

  # test features
  testFeatures = evaled'.config._m.features;

  # defaults that can be applied on tests
  defaults =
    filter
      (d:
        (intersectLists d.features testFeatures) == d.features ||
        (length d.features) == 0
      )
      testing.defaults;

  # add default modules to all modules
  modulesWithDefaults = modules ++ (map (d: d.default) defaults);

  # evaled test
  evaled =
    let
      evaled' = kubenix.evalModules {
        modules = modulesWithDefaults;
      };
    in
    if testing.throwError then evaled'
    else if (builtins.tryEval evaled'.config.test.assertions).success
    then evaled' else null;

in
{
  options = {
    module = mkOption {
      description = "Module defining kubenix test";
      type = types.unspecified;
    };

    evaled = mkOption {
      description = "Test evaulation result";
      type = types.nullOr types.attrs;
      internal = true;
    };

    success = mkOption {
      description = "Whether test assertions were successfull";
      type = types.bool;
      internal = true;
      default = false;
    };

    # transparently forwarded from the test's `test` attribute for ease of access
    name = mkOption {
      description = "test name";
      type = types.str;
      internal = true;
    };

    description = mkOption {
      description = "test description";
      type = types.str;
      internal = true;
    };

    enable = mkOption {
      description = "Whether to enable test";
      type = types.bool;
      internal = true;
    };

    assertions = mkOption {
      description = "Test result";
      type = types.unspecified;
      internal = true;
      default = [ ];
    };

    script = mkOption {
      description = "Test script to use for e2e test";
      type = types.nullOr (types.either types.lines types.path);
      internal = true;
    };

  };

  config = mkMerge [
    {
      inherit evaled;
      inherit (testConfig) name description enable;
    }

    # if test is evaled check assertions
    (mkIf (config.evaled != null) {
      inherit (evaled.config.test) assertions script;

      # if all assertions are true, test is successfull
      success = all (el: el.assertion) config.assertions;
    })
  ];
}

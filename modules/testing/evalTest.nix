{ lib, config, testing, kubenix, ... }:
with lib; let
  modules = [
    # testing module
    config.module

    ./test-options.nix
    ../base.nix

    # passthru some options to test
    {
      config = {
        kubenix.project = mkDefault config.name;
        _module.args =
          {
            inherit kubenix;
            test = evaled.config;
          }
          // testing.args;
      };
    }
  ];

  # eval without checking
  evaled' = kubenix.evalModules {
    modules = modules ++ [{
      _module.args.check = false;
    }];
  };

  # test configuration
  testConfig = evaled'.config.test;

  # test features
  testFeatures = evaled'.config._m.features;

  # common options that can be applied on this test
  commonOpts = filter
    (d:
      (intersectLists d.features testFeatures)
      == d.features
      || (length d.features) == 0
    )
    testing.common;

  # add common options modules to all modules
  modulesWithCommonOptions = modules ++ (map (d: d.options) commonOpts);

  # evaled test
  evaled =
    let
      evaled' = kubenix.evalModules {
        modules = modulesWithCommonOptions;
      };
    in
    if testing.doThrowError
    then evaled'
    else if (builtins.tryEval evaled'.config.test.assertions).success
    then evaled'
    else null;
in
{
  options = {
    module = mkOption {
      description = "Module defining kubenix test";
      type = types.unspecified;
    };

    evaled = mkOption {
      description = "Test evaluation result";
      type = types.nullOr types.attrs;
      internal = true;
    };

    success = mkOption {
      description = "Whether test assertions were successful";
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

      # if all assertions are true, test is successful
      success = all (el: el.assertion) config.assertions;
    })
  ];
}

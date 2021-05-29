{ lib, config, pkgs, ... }:

with lib;
let
  testing = config.testing;
  cfg = testing.driver.kubetest;

  kubetest = import ./kubetestdrv.nix { inherit pkgs; };

  pythonEnv = pkgs.python38.withPackages (ps: with ps; [
    pytest
    kubetest
    kubernetes
  ] ++ cfg.extraPackages);

  toTestScript = t:
    if isString t.script
    then
      pkgs.writeText "${t.name}.py" ''
        ${cfg.defaultHeader}
        ${t.script}
      ''
    else t.script;

  tests = pkgs.linkFarm "${testing.name}-tests" (
    map
      (t: {
        path = toTestScript t;
        name = "${t.name}_test.py";
      })
      (filter (t: t.script != null) testing.tests)
  );

  testScript = pkgs.writeScript "test-${testing.name}.sh" ''
    #!/usr/bin/env bash
    ${pythonEnv}/bin/pytest -p no:cacheprovider ${tests} $@
  '';

in
{
  options.testing.driver.kubetest = {
    defaultHeader = mkOption {
      type = types.lines;
      description = "Default test header";
      default = ''
        import pytest
      '';
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      description = "Extra packages to pass to tests";
      default = [ ];
    };
  };

  config.testing.testScript = testScript;
}

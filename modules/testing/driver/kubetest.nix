{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  inherit (config) testing;
  cfg = testing.driver.kubetest;

  kubetest = import ./kubetestdrv.nix {inherit pkgs;};

  pythonEnv = pkgs.python38.withPackages (ps:
    with ps;
      [
        pytest
        kubetest
        kubernetes
      ]
      ++ cfg.extraPackages);

  toTestScript = t:
    if isString t.script
    then
      pkgs.writeText "${t.name}.py" ''
        ${cfg.defaultHeader}
        ${t.script}
      ''
    else t.script;

  tests = let
    # make sure tests are prefixed so that alphanumerical
    # sorting reproduces them in the same order as they
    # have been declared in the list.
    seive = t: t.script != null && t.enabled;
    allEligibleTests = filter seive testing.tests;
    listLengthPadding = builtins.length (
      lib.stringToCharacters (
        builtins.toString (
          builtins.length allEligibleTests
        )
      )
    );
    op = i: t: {
      path = toTestScript t;
      name = let
        prefix = lib.fixedWidthNumber listLengthPadding i;
      in "${prefix}_${t.name}_test.py";
    };
  in
    pkgs.linkFarm "${testing.name}-tests" (
      lib.imap0 op allEligibleTests
    );

  testScript = pkgs.writeScript "test-${testing.name}.sh" ''
    #!/usr/bin/env bash
    ${pythonEnv}/bin/pytest -p no:cacheprovider ${tests} $@
  '';
in {
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
      default = [];
    };
  };

  config.testing.testScript = testScript;
}

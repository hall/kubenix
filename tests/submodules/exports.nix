{
  name,
  config,
  lib,
  kubenix,
  subm-lib,
  ...
}:
with lib; let
  submodule = {
    imports = [kubenix.modules.submodule];

    config.submodule = {
      name = "subm";
      exports = {
        inherit id;
      };
    };
  };
in {
  imports = with kubenix.modules; [test submodules];

  test = {
    name = "submodules-exports";
    description = "Submodules exports test";
    assertions = [
      {
        message = "should have library exported";
        assertion = subm-lib.id 1 == 1;
      }
    ];
  };

  submodules.imports = [
    {
      modules = [submodule];
      exportAs = "subm-lib";
    }
  ];
}

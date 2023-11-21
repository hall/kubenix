{ config, kubenix, ... }:
let
  configMapData = (builtins.head config.kubernetes.objects).data;
in
{
  imports = [ kubenix.modules.test kubenix.modules.k8s ];

  test = {
    name = "k8s-simple";
    description = "Test that ConfigMap data keys can have a leading underscore (https://github.com/hall/kubenix/issues/44)";
    assertions = [
      {
        message = "leading underscore in ConfigMap key should be preserved";
        assertion = configMapData == { _FOO = "_bar"; };
      }
    ];
  };

  kubernetes.resources.configMaps.foo.data._FOO = "_bar";
}

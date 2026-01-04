{ config, kubenix, lib, ... }:
let
  cfg = config.kubernetes;

  # Helper to check if a string contains another string
  contains = str: substr:
    builtins.match ".*${substr}.*" str != null;

  # Helper to read the resultYAML file
  resultYAMLContent = builtins.readFile cfg.resultYAML;
in
{
  imports = [ kubenix.modules.test kubenix.modules.k8s ];

  kubernetes.resources.pods.test-pod = {
    spec.containers.nginx.image = "nginx";
  };

  test = {
    name = "k8s-hash-label";
    description = "Test checking whether resultYAML contains hash labels";
    assertions = [
      {
        message = "resultYAML should contain kubenix/hash label when addHashLabel is true (default)";
        assertion = contains resultYAMLContent "kubenix/hash";
      }
    ];
  };
}

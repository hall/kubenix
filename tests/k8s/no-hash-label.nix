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

  kubernetes.addHashLabel = false;

  test = {
    name = "k8s-no-hash-label";
    description = "Test checking whether resultYAML does NOT contain hash labels when addHashLabel is false";
    assertions = [
      {
        message = "resultYAML should NOT contain kubenix/hash label when addHashLabel is false";
        assertion = !(contains resultYAMLContent "kubenix/hash");
      }
    ];
  };
}

{ config, lib, pkgs, kubenix, ... }:

with lib;

{
  imports = [ kubenix.modules.test ./module.nix ];

  test = {
    name = "nginx-deployment";
    description = "Test testing nginx deployment";
    testScript = ''
      kube.wait_until_succeeds("docker load --input='${config.docker.images.nginx.image}'")
      kube.wait_until_succeeds("kubectl apply -f ${config.kubernetes.result}")

      kube.succeed("kubectl get deployment | grep -i nginx")
      kube.wait_until_succeeds("kubectl get deployment -o go-template nginx --template={{.status.readyReplicas}} | grep 10")
      kube.wait_until_succeeds({pkgs.curl}/bin/curl http://nginx.default.svc.cluster.local | grep -i hello")
    '';
  };
}

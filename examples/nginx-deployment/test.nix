{ config, lib, pkgs, kubenix, test, ... }:

with lib;

{
  imports = [ kubenix.modules.test ./module.nix ];

  test = {
    name = "nginx-deployment";
    description = "Test testing nginx deployment";
    script = ''
      @pytest.mark.applymanifest('${test.kubernetes.resultYAML}')
      def test_nginx_deployment(kube):
          """Tests whether nginx deployment gets successfully created"""

          kube.wait_for_registered(timeout=30)

          deployments = kube.get_deployments()
          nginx_deploy = deployments.get('nginx')
          assert nginx_deploy is not None

          status = nginx_deploy.status()
          assert status.readyReplicas == 10

          # TODO: implement those kind of checks from the host machine into the cluster
          # via port forwarding, prepare all runtimes accordingly
          # ${pkgs.curl}/bin/curl http://nginx.default.svc.cluster.local | grep -i hello
    '';
  };
}

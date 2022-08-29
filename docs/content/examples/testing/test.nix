{
  lib,
  pkgs,
  kubenix,
  test,
  ...
}: {
  imports = [kubenix.modules.test];

  test = {
    name = "example";
    description = "can reach deployment";
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
    '';
  };
}

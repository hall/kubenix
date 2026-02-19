{ pkgs
, kubenix
, ...
}:
let
  testKubenix = kubenix.override {
    module = { kubenix, ... }: {
      imports = [ kubenix.modules.k8s ];

      kubernetes.resources.configMaps = {
        test-instance-a = {
          metadata.labels."kubenix/module-instance" = "instance-a";
          data.testkey = "value-a";
        };
        test-instance-b = {
          metadata.labels."kubenix/module-instance" = "instance-b";
          data.testkey = "value-b";
        };
      };
    };
  };
in
pkgs.testers.runNixOSTest {
  name = "kubenix-label-filter";

  nodes.k3s = { pkgs, ... }: {
    environment.systemPackages = [
      testKubenix
      pkgs.kubectl
    ];

    networking.firewall.enable = false;

    virtualisation = {
      memorySize = 2048;
      diskSize = 4096;
      cores = 2;
    };

    services.k3s = {
      enable = true;
      role = "server";
      extraFlags = [
        "--disable=traefik"
        "--disable=servicelb"
        "--disable=coredns"
        "--disable=local-storage"
        "--disable=metrics-server"
      ];
    };

    environment.sessionVariables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };

  testScript = ''
    k3s.wait_for_unit("k3s")
    k3s.wait_until_succeeds("kubectl get nodes | grep ' Ready'", timeout=60)
    k3s.wait_until_succeeds("kubectl get serviceaccount default", timeout=60)

    with subtest("kubenix render shows both instances"):
        result = k3s.succeed("kubenix render")
        assert "instance-a" in result, "instance-a not in render output"
        assert "instance-b" in result, "instance-b not in render output"

    with subtest("kubenix apply -l deploys only instance-a"):
        k3s.succeed("kubenix apply -l kubenix/module-instance=instance-a")
        result = k3s.succeed("kubectl get configmap -o name | sort")
        assert "test-instance-a" in result, "instance-a should be deployed"
        assert "test-instance-b" not in result, "instance-b should NOT be deployed with -l filter"

    with subtest("kubenix apply -l deploys instance-b separately"):
        k3s.succeed("kubenix apply -l kubenix/module-instance=instance-b")
        result = k3s.succeed("kubectl get configmap -o name | sort")
        assert "test-instance-a" in result, "instance-a should still exist"
        assert "test-instance-b" in result, "instance-b should now be deployed"

    with subtest("kubectl delete -l removes only instance-a"):
        k3s.succeed("kubenix render | kubectl delete -l kubenix/module-instance=instance-a -f -")
        result = k3s.succeed("kubectl get configmap -o name | sort")
        assert "test-instance-a" not in result, "instance-a should be deleted"
        assert "test-instance-b" in result, "instance-b should still exist"
  '';
}

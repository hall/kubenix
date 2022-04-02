# nixos-k8s implements nixos kubernetes testing runtime
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  inherit (config) testing;
  # kubeconfig = "/etc/${config.services.kubernetes.pki.etcClusterAdminKubeconfig}";
  kubeconfig = "/etc/kubernetes/cluster-admin.kubeconfig";
  kubecerts = "/var/lib/kubernetes/secrets";

  # how we differ from the standard configuration of mkKubernetesBaseTest
  extraConfiguration = {
    config,
    ...
  }: {
    virtualisation = {
      memorySize = 2048;
    };

    networking = {
      nameservers = ["10.0.0.254"];
      firewall = {
        trustedInterfaces = ["docker0" "cni0"];
      };
    };

    services.kubernetes = {
      flannel.enable = false;
      kubelet = {
        seedDockerImages = testing.docker.images;
        networkPlugin = "cni";
        cni.config = [
          {
            name = "mynet";
            type = "bridge";
            bridge = "cni0";
            addIf = true;
            ipMasq = true;
            isGateway = true;
            ipam = {
              type = "host-local";
              subnet = "10.1.0.0/16";
              gateway = "10.1.0.1";
              routes = [
                {
                  dst = "0.0.0.0/0";
                }
              ];
            };
          }
        ];
      };
    };

    systemd = {
      extraConfig = "DefaultLimitNOFILE=1048576";
      # Host tools should have a chance to access guest's kube api
      services.copy-certs = {
        description = "Share k8s certificates with host";
        script = "cp -rf ${kubecerts} /tmp/xchg/; cp -f ${kubeconfig} /tmp/xchg/;";
        after = ["kubernetes.target"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
    };
  };

  script = ''
    machine1.succeed("${testing.testScript} --kube-config=${kubeconfig}")
  '';

  test = with import "${pkgs.path}/nixos/tests/kubernetes/base.nix" {
    inherit pkgs;
    inherit (pkgs) system;
  };
    mkKubernetesSingleNodeTest {
      inherit extraConfiguration;
      inherit (config.testing) name;
      test = script;
    };
in {
  options.testing.runtime.nixos-k8s = {
    driver = mkOption {
      description = "Test driver";
      type = types.package;
      internal = true;
    };
  };

  config.testing.runtime.nixos-k8s.driver = test.driver;
}

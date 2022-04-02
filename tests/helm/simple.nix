{ config, lib, pkgs, kubenix, helm, ... }:

with lib;
with kubenix.lib;
with pkgs.dockerTools;
let
  corev1 = config.kubernetes.api.resources.core.v1;
  appsv1 = config.kubernetes.api.resources.apps.v1;

  postgresql = pullImage {
    imageName = "docker.io/bitnami/postgresql";
    imageDigest = "sha256:ec16eb9ff2e7bf0669cfc52e595f17d9c52efd864c3f943f404d525dafaaaf96";
    sha256 = "12jr8pzvj1qglrp7sh857a5mv4nda67hw9si6ah2bl6y1ff19l65";
    finalImageName = "docker.io/bitnami/postgresql";
    finalImageTag = "11.7.0-debian-10-r55";
  };

  postgresqlExporter = pullImage {
    imageName = "docker.io/bitnami/postgres-exporter";
    imageDigest = "sha256:373ba8ac1892291b4121591d1d933b7f9501ae45b9b8d570d7deb4900f91cfe9";
    sha256 = "0icrqmlj8127jhmiy3vh419cv7hwnw19xdn89hxxyj2l6a1chryh";
    finalImageName = "docker.io/bitnami/postgres-exporter";
    finalImageTag = "0.9.0-debian-10-r43";
  };

  bitnamiShell = pullImage {
    imageName = "docker.io/bitnami/bitnami-shell";
    imageDigest = "sha256:58ba68e1f1d9a55c1234ae5b439bdcf0de1931e4aa1bac7bd0851b66de14fd97";
    sha256 = "00lmphm3ds17apbmh2m2r7cz05jhp4dc3ynswrj0pbpq0azif4zn";
    finalImageName = "docker.io/bitnami/bitnami-shell";
    finalImageTag = "10";
  };
in
{
  imports = [ kubenix.modules.test kubenix.modules.helm kubenix.modules.k8s kubenix.modules.docker ];

  docker.images = {
    postgresql.image = postgresql;
    postgresqlExporter.image = postgresqlExporter;
    bitnamiShell.image = bitnamiShell;
  };

  test = {
    name = "helm-simple";
    description = "Simple k8s testing wheter name, apiVersion and kind are preset";
    assertions = [{
      message = "should have generated resources";
      assertion =
        appsv1.StatefulSet ? "app-psql-postgresql-primary" &&
        appsv1.StatefulSet ? "app-psql-postgresql-read" &&
        corev1.Secret ? "app-psql-postgresql" &&
        corev1.Service ? "app-psql-postgresql-headless";
    }
      {
        message = "should have values passed";
        assertion = appsv1.StatefulSet.app-psql-postgresql-read.spec.replicas == 2;
      }
      {
        message = "should have namespace defined";
        assertion =
          appsv1.StatefulSet.app-psql-postgresql-primary.metadata.namespace == "test";
      }];
    script = ''
      @pytest.mark.applymanifest('${config.kubernetes.resultYAML}')
      def test_helm_deployment(kube):
          """Tests whether helm deployment gets successfully created"""

          kube.wait_for_registered(timeout=30)

          # TODO: implement those kind of checks from the host machine into the cluster
          # via port forwarding, prepare all runtimes accordingly
          # PGPASSWORD=postgres ${pkgs.postgresql}/bin/psql -h app-psql-postgresql.test.svc.cluster.local -U postgres -l
    '';
  };

  kubernetes.helm.instances.app-psql = {
    namespace = "some-overridden-by-kubetest";
    chart = helm.fetch {
      repo = "https://charts.bitnami.com/bitnami";
      chart = "postgresql";
      version = "10.3.8";
      sha256 = "sha256-0hJ5pNIivpXeRal1DwJ2VSD3Yxtw2omOoIYGZKGtu9I=";
    };

    values = {
      image = {
        repository = "bitnami/postgresql";
        tag = "11.11.0-debian-10-r71";
        pullPolicy = "IfNotPresent";
      };
      volumePermissions.image = {
        repository = "bitnami/bitnami-shell";
        tag = "10";
        pullPolicy = "IfNotPresent";
      };
      metrics.image = {
        repository = "bitnami/postgres-exporter";
        tag = "0.9.0-debian-10-r43";
        pullPolicy = "IfNotPresent";
      };
      replication.enabled = true;
      replication.slaveReplicas = 2;
      postgresqlPassword = "postgres";
      persistence.enabled = false;
    };
  };
}

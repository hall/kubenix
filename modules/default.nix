{
  k8s = ./k8s.nix;
  istio = ./istio.nix;
  submodules = ./submodules.nix;
  submodule = ./submodule.nix;
  helm = ./helm.nix;
  docker = ./docker.nix;
  docker-image-from-package = ./docker-image-from-package.nix;
  testing = ./testing;
  test = ./testing/test-options.nix;
  base = ./base.nix;
}

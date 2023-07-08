{ pkgs, lib }:
let
  generateIstio = import ./istio {
    inherit pkgs lib;
  };

  generateK8S = name: spec:
    import ./k8s {
      inherit name pkgs lib spec;
    };
in
{
  istio = pkgs.linkFarm "istio-generated" [{
    name = "latest.nix";
    path = generateIstio;
  }];

  k8s = pkgs.linkFarm "k8s-generated" (
    builtins.attrValues (
      builtins.mapAttrs
        (version: sha:
          let
            short = builtins.concatStringsSep "." (lib.lists.sublist 0 2 (builtins.splitVersion version));
          in
          {
            name = "v${short}.nix";
            path = generateK8S "v${short}" (builtins.fetchurl {
              url = "https://github.com/kubernetes/kubernetes/raw/v${version}/api/openapi-spec/swagger.json";
              sha256 = sha;
            });
          }
        )
        (import ../../versions.nix).full
    )
  );
}

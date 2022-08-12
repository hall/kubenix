{
   pkgs,
   lib,
}: let
  generateIstio = import ./istio {
    inherit
      pkgs
      lib
      ;
  };

  generateK8S = name: spec:
    import ./k8s {
      inherit
        name
        pkgs
        lib
        spec
        ;
    };
in {
  istio = pkgs.linkFarm "istio-generated" [
    {
      name = "latest.nix";
      path = generateIstio;
    }
  ];

  k8s = pkgs.linkFarm "k8s-generated" [
    {
      name = "v1.19.nix";
      path = generateK8S "v1.19" (builtins.fetchurl {
        url = "https://github.com/kubernetes/kubernetes/raw/v1.19.10/api/openapi-spec/swagger.json";
        sha256 = "sha256-ZXxonUAUxRK6rhTgK62ytTdDKCuOoWPwxJmktiKgcJc=";
      });
    }

    {
      name = "v1.20.nix";
      path = generateK8S "v1.20" (builtins.fetchurl {
        url = "https://github.com/kubernetes/kubernetes/raw/v1.20.6/api/openapi-spec/swagger.json";
        sha256 = "sha256-xzVOarQDSomHMimpt8H6MfpiQrLl9am2fDvk/GfLkDw=";
      });
    }

    {
      name = "v1.21.nix";
      path = generateK8S "v1.21" (builtins.fetchurl {
        url = "https://github.com/kubernetes/kubernetes/raw/v1.21.0/api/openapi-spec/swagger.json";
        sha256 = "sha256-EoqYTbtaTlzs7vneoNtXUmdnjTM/U+1gYwCiEy0lOcw=";
      });
    }
    {
      name = "v1.23.nix";
      path = generateK8S "v1.23" (builtins.fetchurl {
        url = "https://github.com/kubernetes/kubernetes/raw/v1.23.0/api/openapi-spec/swagger.json";
        sha256 = "sha256:0jivg8nlxka1y7gzqpcxkmbvhcbxynyrxmjn0blky30q5064wx2a";
      });
    }
    {
      name = "v1.24.nix";
      path = generateK8S "v1.24" (builtins.fetchurl {
        url = "https://github.com/kubernetes/kubernetes/raw/v1.24.0/api/openapi-spec/swagger.json";
        sha256 = "sha256:0fp5hbqk2q0imrfi4mwp1ia0bmn0xnl6hcr07y52q2cp41pmfhqd";
      });
    }
  ];
}

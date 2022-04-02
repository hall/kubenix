{pkgs ? import <nixpkgs> {}}: let
  fetchhelm = pkgs.callPackage ./fetchhelm.nix {};
  chart2json = pkgs.callPackage ./chart2json.nix {};
in rec {
  postgresql-chart = fetchhelm {
    chart = "stable/postgresql";
    version = "0.18.1";
    sha256 = "1p3gfmaakxrqb4ncj6nclyfr5afv7xvcdw95c6qyazfg72h3zwjn";
  };

  istio-chart = fetchhelm {
    chart = "istio";
    version = "1.1.0";
    repo = "https://storage.googleapis.com/istio-release/releases/1.1.0-rc.0/charts";
    sha256 = "0ippv2914hwpsb3kkhk8d839dii5whgrhxjwhpb9vdwgji5s7yfl";
  };

  istio-official-chart = pkgs.fetchgit {
    url = "https://github.com/fyery-chen/istio-helm";
    rev = "47e235e775314daeb88a3a53689ed66c396ecd3f";
    sha256 = "190sfyvhdskw6ijy8cprp6hxaazn7s7mg5ids4snshk1pfdg2q8h";
  };

  postgresql-json = chart2json {
    name = "postgresql";
    chart = postgresql-chart;
    values = {
      networkPolicy.enabled = true;
    };
  };

  istio-json = chart2json {
    name = "istio";
    chart = istio-chart;
  };

  istio-official-json = chart2json {
    name = "istio-official";
    chart = "${istio-official-chart}/istio-official";
  };
}

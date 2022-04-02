{pkgs}: {
  chart2json = pkgs.callPackage ./chart2json.nix {};
  fetch = pkgs.callPackage ./fetchhelm.nix {};
}

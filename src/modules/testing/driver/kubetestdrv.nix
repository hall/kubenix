{ pkgs ? import <nixpkgs> { } }:
with pkgs;
with pkgs.python38Packages;

with pkgs.python38;
pkgs.python38Packages.buildPythonPackage rec {
  pname = "kubetest";
  version = "0.9.5";
  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-TqDHMciAEXv4vMWLJY1YdtXsP4ho+INgdFB3xQQNoZU=";
  };
  propagatedBuildInputs = [ pytest kubernetes ];
  doCheck = false;
}

let
  fetch = import ./lib/compat.nix;
in
{ pkgs ? import (fetch "nixpkgs") { }
, lib ? pkgs.lib
, throwError ? true
}:

with lib;
let
  kubenix = import ./. { inherit pkgs; };

  lib = kubenix.lib;

  runK8STests = k8sVersion: import ./tests {
    inherit pkgs lib kubenix k8sVersion throwError nixosPath;
  };
in
rec {

  tests = {
    k8s-1_19 = runK8STests "1.19";
    k8s-1_20 = runK8STests "1.20";
    k8s-1_21 = runK8STests "1.21";
  };

  test-check =
    if !(all (test: test.success) (attrValues tests))
    then throw "tests failed"
    else true;

  examples = import ./examples { };
}

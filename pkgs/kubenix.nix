{
  lib,
  writeShellScriptBin,
  coreutils,
  nix,
  jq,
  kubectl,
}: let
  name = "kubenix";
in
  lib.recursiveUpdate (writeShellScriptBin name ''
    set -Eeuo pipefail

    NAME=${name}
    function help() {
      echo "
      kubenix - Kubernetes resource management with Nix

      commands:
        apply    - create resources in target cluster
        diff     - show a diff between rendered and live resources
        render   - print resource manifests to stdout
      "
    }

    MANIFEST="$(${nix}/bin/nix eval '.#k8s.config.kubernetes.result' --raw)"

    function apply() {
      ${kubectl}/bin/kubectl apply -f $MANIFEST
    }

    function render() {
      cat $MANIFEST | ${jq}/bin/jq
    }

    function diff() {
      ${kubectl}/bin/kubectl diff -f $MANIFEST
    }

    while test $# -gt 0; do
      case "$1" in
        apply|"")
          shift
          apply
          ;;
        diff)
          shift
          diff
          ;;
        render)
          shift
          render
          ;;
        -h|--help)
          help
          exit 0
          ;;
        -v|--verbose)
          shift
          set -x
          ;;
        *)
          help
          exit 1
          ;;
      esac
    done


  '')
  {meta.description = "";}

{
  lib,
  writeShellScriptBin,
  coreutils,
  nix,
  jq,
}: let
  name = "kubenix";
in
  lib.recursiveUpdate
  (writeShellScriptBin name ''
    set -Eeuo pipefail

    NAME=${name}
    function help() {
      echo "
      kubenix - Kubernetes resource management with Nix

      commands:
        apply    - create resources in target cluster
        render   - print resource manifests to stdout
      "
    }

    function apply() {
      echo not impremented
    }

    function render() {
      ${nix}/bin/nix eval '.#kubernetes' # | ${jq}/bin/jq 'fromjson'
    }

    while test $# -gt 0; do
      case "$1" in
        apply|"")
          shift
          apply
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

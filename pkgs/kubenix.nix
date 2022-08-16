{ lib
, writeShellScriptBin
, nix
, jq
, kubectl
, kubernetes-helm
,
}:
writeShellScriptBin "kubenix" ''
  set -Eeuo pipefail

  function _help() {
    echo "
    kubenix - Kubernetes resource management with Nix

    commands:
      apply    - create resources in target cluster
      diff     - show a diff between configured and live resources
      render   - print resource manifests to stdout
    "
  }

  function _helm() {
    RELEASES="$(${nix}/bin/nix eval '.#k8s.config.kubernetes.helm' --json | jq -c '.releases[] | del(.objects)')"
    [ -n "$RELEASES" ] || return 0

    for release in $RELEASES; do
      values=$(mktemp)
      echo $release | jq -r '.values' > $values

      ${kubernetes-helm}/bin/helm $@ \
        -n $(echo $release | jq -r '.namespace // "default"') \
        $(echo $release | jq -r '.name') \
        $(echo $release | jq -r '.chart') \
        -f $values
    done
  }

  function _kubectl() {
    MANIFESTS=$(mktemp)
    # TODO: find a better filter, not just not-helm, not-crd
    cat $(${nix}/bin/nix build '.#k8s.config.kubernetes.result' --json | jq -r '.[0].outputs.out') \
     | jq '.items[]
       | select(.metadata.labels."app.kubernetes.io/managed-by" != "Helm")
       | select(.kind != "CustomResourceDefinition")' > $MANIFESTS

    [ -n "$MANIFESTS" ] || return 0

    case $1 in
      render)
        cat $MANIFESTS;;
      *)
        ${kubectl}/bin/kubectl $@ -f $MANIFESTS;;
    esac
  }

  # if no args given, add empty string
  [ $# -eq 0 ] && set -- ""

  # parse arguments
  while test $# -gt 0; do
    case "$1" in

      apply)
        _kubectl apply
        _helm upgrade --install --create-namespace
        shift;;

      diff)
        _kubectl diff
        _helm diff upgrade --allow-unreleased
        shift;;

      render)
        _kubectl render
        _helm template
        shift;;

      -h|--help|"")
        _help
        exit 0;;

      -v|--verbose)
        set -x
        shift;;

      *)
        _help
        exit 1;;

      esac
    done
''

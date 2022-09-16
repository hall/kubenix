{
  jq,
  kubectl,
  kubernetes-helm,
  nix,
  vals,
  writeShellScriptBin,
}:
writeShellScriptBin "kubenix" ''
  set -Eeuo pipefail

  function _help() {
    echo "
    kubenix - Kubernetes management with Nix

    commands:
      apply    - create resources in target cluster
      diff     - show a diff between configured and live resources
      render   - print resource manifests to stdout

    options:
      -h --help     - show this menu
      -v --verbose  - increase output details
    "
  }

  function _helm() {
    ${nix}/bin/nix eval '.#kubenix.config.kubernetes.helm' --json | jq -c '.releases[] | del(.objects)' | while read -r release; do
      values=$(mktemp)
      echo "$release" | jq -r '.values' | ${vals}/bin/vals eval > $values

      ${kubernetes-helm}/bin/helm $@ \
        -n $(echo "$release" | jq -r '.namespace // "default"') \
        $(echo "$release" | jq -r '.name') \
        $(echo "$release" | jq -r '.chart') \
        -f $values
    done
  }

  function _kubectl() {
    MANIFESTS=$(mktemp)
    # TODO: find a better filter, not just not-helm, not-crd
    resources=$(${nix}/bin/nix build '.#kubenix.config.kubernetes.result' --json | jq -r '.[0].outputs.out')
    cat $resources | jq '.items[]
       | select(.metadata.labels."app.kubernetes.io/managed-by" != "Helm")
       | select(.kind != "CustomResourceDefinition")' > $MANIFESTS

    [ -s "$MANIFESTS" ] || return 0

    case $1 in
      render)
        cat $MANIFESTS;;
      *)
        cat $MANIFESTS | ${vals}/bin/vals eval | ${kubectl}/bin/kubectl $@ -f - || true;;
    esac
  }

  # if no args given, add empty string
  [ $# -eq 0 ] && set -- ""

  # use kubeconfig, if given
  kubeconfig=$(nix eval '.#kubenix.config.kubernetes.kubeconfig' --raw)
  [ -n "$kubeconfig" ] && export KUBECONFIG=$kubeconfig

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

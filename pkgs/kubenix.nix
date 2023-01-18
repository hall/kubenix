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

  # path to nix binary (useful to inject flags, e.g.)
  _nix="${nix}/bin/nix"

  SYSTEM=$($_nix show-config --json | jq -r '.system.value')

  function _helm() {
    $_nix eval ".#kubenix.$SYSTEM.config.kubernetes.helm" --json | jq -c '.releases[] | del(.objects)' | while read -r release; do
      values=$(mktemp)
      echo "$release" | jq -r '.values' | ${vals}/bin/vals eval > $values

      name=$(echo "$release" | jq -r '.name')
      chart=$(echo "$release" | jq -r '.chart')
      namespace=$(echo "$release" | jq -r '.namespace // "default"')

      args="-n $namespace $name $chart -f $values"

      # only apply when there are changes
      if [[ "$1" == "upgrade" ]]; then
        if ${kubernetes-helm}/bin/helm diff upgrade $args --allow-unreleased --detailed-exitcode 2> /dev/null; then
           continue
        fi
      fi

      ${kubernetes-helm}/bin/helm $@ $args
    done
  }

  function _kubectl() {
    MANIFESTS=$(mktemp)
    # TODO: find a better filter, not just not-helm, not-crd
    resources=$($_nix build ".#kubenix.$SYSTEM.config.kubernetes.result" --json | jq -r '.[0].outputs.out')
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
  kubeconfig=$($_nix eval ".#kubenix.$SYSTEM.config.kubernetes.kubeconfig" --raw)
  [ -n "$kubeconfig" ] && export KUBECONFIG=$kubeconfig

  # parse arguments
  while test $# -gt 0; do
    case "$1" in

      apply)
        _kubectl apply
        _helm upgrade --atomic --install --create-namespace
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
       _nix="$_nix --show-trace"
        set -x
        shift;;

      *)
        _help
        exit 1;;

      esac
    done
''

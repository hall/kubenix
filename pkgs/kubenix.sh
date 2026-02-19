#!/usr/bin/env bash
set -euo pipefail

function _help() {
  echo "
  kubenix - Kubernetes management with Nix

  commands:
    ""          - run diff, prompt for confirmation, then apply
    apply       - create resources in target cluster
    diff        - show a diff between configured and live resources
    render      - print resource manifests to stdout

  options:
    -h --help   - show this menu
  "
}

function _kubectl() {
  vals eval -fail-on-missing-key-in-map <"$MANIFEST" | kubectl "$@"
}

case "${1:-}" in
-h | --help)
  _help
  ;;

"")
  _kubectl diff -f - --prune || (
    read -r -p 'apply? [y/N]: ' response
    [[ $response == "y" ]] && _kubectl apply -f - --prune --all
  )
  ;;

render)
  vals eval <"$MANIFEST"
  ;;

apply | diff)
  _kubectl "$@" -f - --prune
  ;;

*)
  _kubectl "$@"
  ;;
esac

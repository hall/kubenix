#!/usr/bin/env bash

set -uo pipefail

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
  vals eval -fail-on-missing-key-in-map <$MANIFEST | kubectl $@
}

# if no args given, add empty string
[ $# -eq 0 ] && set -- ""

# parse arguments
while test $# -gt 0; do
  case "$1" in

  -h | --help)
    _help
    exit 0
    ;;

  "")
    _kubectl diff -f - --prune
    if [[ $? -eq 1 ]]; then
      read -p 'apply? [y/N]: ' response
      [[ $response == "y" ]] && _kubectl apply -f - --prune --all
    fi
    shift
    ;;

  render)
    vals eval <$MANIFEST
    shift
    ;;

  apply | diff)
    _kubectl $@ -f - --prune
    shift
    ;;

  *)
    _kubectl $@
    shift
    ;;

  esac
done

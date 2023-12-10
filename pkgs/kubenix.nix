{ kubectl
, vals
, colordiff
, evalModules
, runCommand
, writeShellScript
, module ? { }
, specialArgs ? { }
}:
let
  kubernetes = (evalModules {
    inherit module specialArgs;
  }).config.kubernetes or { };
in
runCommand "kubenix"
{
  inherit (kubernetes) kubeconfig;
  result = kubernetes.result or "";

  # kubectl does some parsing which removes the -I flag so
  # as workaround, we write to a script and call that
  # https://github.com/kubernetes/kubernetes/pull/108199#issuecomment-1058405404
  diff = writeShellScript "kubenix-diff" ''
    ${colordiff}/bin/colordiff --nobanner -N -u -I ' kubenix/hash: ' -I ' generation: ' $@
  '';
} ''
  set -euo pipefail
  mkdir -p $out/bin

  # write the manifests for use with `nix build`
  ln -s $result $out/manifest.json

  # create a script for `nix run`
  cat <<EOF> $out/bin/kubenix
    set -uo pipefail

    export KUBECONFIG=$kubeconfig
    export KUBECTL_EXTERNAL_DIFF=$diff

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
      ${vals}/bin/vals eval -fail-on-missing-key-in-map < $result | ${kubectl}/bin/kubectl \$@
    }

    # if no args given, add empty string
    [ \$# -eq 0 ] && set -- ""

    # parse arguments
    while test \$# -gt 0; do
      case "\$1" in

        -h|--help)
          _help
        exit 0;;

        "")
          _kubectl diff -f - --prune
          if [[ "\$?" -eq 1 ]]; then
            read -p 'apply? [y/N]: ' response
            [[ \$response == "y" ]] && _kubectl apply -f - --prune --all
          fi
         shift;;

        render)
          ${vals}/bin/vals eval < $result
        shift;;

        apply|diff)
          _kubectl \$@ -f - --prune
        shift;;

        *)
          _kubectl \$@
        shift;;

      esac
    done

  EOF
  chmod +x $out/bin/kubenix
''

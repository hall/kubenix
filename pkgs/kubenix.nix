{ kubectl
, vals
, colordiff
, evalModules
, writeShellScript
, writeScriptBin
, makeWrapper
, symlinkJoin
, lib
, module ? { }
, specialArgs ? { }
}:
let
  kubernetes = (evalModules {
    inherit module specialArgs;
  }).config.kubernetes or { };

  kubeconfig = "/home/pim/.kube/config"; # kubernetes.kubeconfig or "";
  result = kubernetes.result or "";

  # kubectl does some parsing which removes the -I flag so
  # as workaround, we write to a script and call that
  # https://github.com/kubernetes/kubernetes/pull/108199#issuecomment-1058405404
  diff = writeShellScript "kubenix-diff" ''
    ${lib.getExe colordiff} --nobanner -N -u -I ' kubenix/hash: ' -I ' generation: ' $@
  '';

  script = (writeScriptBin "kubenix" (builtins.readFile ./kubenix.sh)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\npatchShebangs $out";
  });
in
symlinkJoin {
  name = "kubenix";
  paths = [ script vals kubectl ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    export DIFF="${diff}"
    wrapProgram $out/bin/kubenix \
      --set PATH "$out/bin" \
      --set KUBECONFIG "${kubeconfig}" \
      --set KUBECTL_EXTERNAL_DIFF "''${DIFF}" \
      --set MANIFEST "${result}"
  '';
}

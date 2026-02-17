{ kubectl
, vals
, colordiff
, evalModules
, writeShellScript
, writeShellApplication
, lib
, module ? { }
, specialArgs ? { }
}:
let
  config = (evalModules {
    inherit module specialArgs;
  }).config or { };
  kubernetes = config.kubernetes or { };

  kubeconfig = kubernetes.kubeconfig or "";
  result = kubernetes.result or "";

  # kubectl does some parsing which removes the -I flag so
  # as workaround, we write to a script and call that
  # https://github.com/kubernetes/kubernetes/pull/108199#issuecomment-1058405404
  diff = writeShellScript "kubenix-diff" ''
    ${lib.getExe colordiff} --nobanner -N -u -I ' kubenix/hash: ' -I ' generation: ' $@
  '';

in
writeShellApplication {
  name = "kubenix";
  runtimeInputs = [ vals kubectl ];
  text = builtins.readFile ./kubenix.sh;
  bashOptions = [ "u" "o pipefail" ];
  runtimeEnv = {
    KUBECONFIG = toString kubeconfig;
    KUBECTL_EXTERNAL_DIFF = toString diff;
    MANIFEST = toString result;
  };
  derivationArgs = {
    passthru = {
      manifest = result;
      config = config;
    };
  };
}

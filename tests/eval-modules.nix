{ pkgs
, evalModules
, ...
}:
let
  inherit (pkgs) lib;

  pod = evalModules {
    module = { kubenix, ... }: {
      imports = [ kubenix.modules.k8s ];
      kubernetes.resources.pods.example.spec.containers.example.image = "nginx";
    };
  };

  # Reaches every member of the `kubenix` special argument from inside a module: `modules` in
  # `imports` position, `lib` in a value position, and `evalModules` for a nested evaluation.
  probe = evalModules {
    module = { kubenix, lib, ... }: {
      imports = [ kubenix.modules.k8s ];

      options.probe = lib.mkOption { type = lib.types.attrs; };

      config.probe = {
        libNamespaces = builtins.attrNames kubenix.lib;
        nested = (kubenix.evalModules {
          module = { kubenix, ... }: {
            imports = [ kubenix.modules.k8s ];
            kubernetes.resources.configMaps.nested.data.key = "value";
          };
        }).config.kubernetes.api.resources.configMaps.nested.metadata.name;
      };
    };
  };

  assertions = [
    {
      message = "evalModules renders a Pod with apiVersion, kind and name";
      assertion =
        let o = pod.config.kubernetes.api.resources.pods.example;
        in o.apiVersion == "v1" && o.kind == "Pod" && o.metadata.name == "example";
    }
    {
      message = "kubenix.modules is reachable from a module's imports";
      assertion = pod.config.kubernetes.api.resources.pods ? example;
    }
    {
      message = "kubenix.lib exposes the k8s, docker and helm namespaces";
      assertion = probe.config.probe.libNamespaces == [ "docker" "helm" "k8s" ];
    }
    {
      message = "kubenix.evalModules supports nested evaluation";
      assertion = probe.config.probe.nested == "nested";
    }
  ];

  failures = map (a: a.message) (builtins.filter (a: !a.assertion) assertions);
in
pkgs.runCommand "kubenix-eval-modules-interface"
{
  passthru = { inherit pod probe; };
}
  (
    if failures == [ ]
    then "echo success > $out"
    else "echo ${lib.escapeShellArg (builtins.concatStringsSep "\n" failures)} >&2; exit 1"
  )

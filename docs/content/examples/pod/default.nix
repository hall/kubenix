# let's creata a function whose only input is the kubenix package
{kubenix ? import ../../../..}:
# evalModules is our main entrypoint
kubenix.evalModules.${builtins.currentSystem} {
  # to it, we pass a module that accepts a (different) kubenix object
  module = {kubenix, ...}: {
    # in order to define options, we need to import their definitions
    imports = with kubenix.modules; [k8s];
    # now we have full access to define Kubernetes resources
    kubernetes.resources.pods.example.spec.containers.ex.image = "nginx";
  };
}

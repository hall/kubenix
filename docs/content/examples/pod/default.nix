# let's create a function whose only input is the kubenix package
{ kubenix ? import ../../../.. }:
# evalModules is our main entrypoint
kubenix.evalModules.${builtins.currentSystem} {
  # to it, we pass a module that accepts a (different) kubenix object
  module = { kubenix, ... }: {
    # in order to define options, we need to import their definitions
    imports = [ kubenix.modules.k8s ];
    # now we have full access to define Kubernetes resources
    kubernetes.resources.pods = {
      # "example" is the name of our pod
      example.spec.containers = {
        # "ex" is the name of the container in our pod
        ex.image = "nginx";
      };
    };
  };
}

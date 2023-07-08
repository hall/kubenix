{ config
, kubenix
, lib
, # Name of submodule instance.
  name
, # This is a shorthand for config.submodule.args and contains
  # final values of the args options.
  args
, ...
}: {
  imports = with kubenix.modules; [
    # This needs to be imported in order to define a submodule.
    submodule
    # Importing this so that we can set config.kubernetes
    # within the context of this submodule.
    k8s
  ];

  # Args are used to pass information from the parent context.
  options.submodule.args = {
    kubernetes = lib.mkOption {
      description = "Kubernetes config to be applied to a specific namespace.";
      # We are not given a precise type to this since we are using it
      # to set kubernetes options from the k8s module which are already
      # precisely typed.
      type = lib.types.attrs;
      default = { };
    };
  };

  config = {
    submodule = {
      # Used to uniquely identify a submodule. Used to select submodule
      # "prototype" when instantiating.
      name = "namespaced";

      # Passthru allows a submodule instance to set config of the parent
      # context. It's not strictly required but it's useful for combining
      # outputs of multiple submodule instances, without having to write
      # ad hoc code in the parent context.

      # NOTE: passthru has not effect if given options are not defined
      # in the parent context. Therefore in this case we are expecting that
      # parent imports kubinex.k8s module.

      # Here we set kubernetes.objects.
      # This is a list so even if distinct instances of the submodule contain
      # definitions of identical api resources, these will not be merged or
      # cause conflicts. Lists of resources from multiple submodule instances
      # will simply be concatenated.
      passthru.kubernetes.objects = config.kubernetes.objects;
    };

    kubernetes = lib.mkMerge [
      # Use instance name as namespace
      { namespace = name; }
      # Create namespace object
      { resources.namespaces.${name} = { }; }
      # All resources defined here will use the above namespace
      args.kubernetes
    ];
  };
}

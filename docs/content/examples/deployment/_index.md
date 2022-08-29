As a more complete example, let's define some high-level variables and then split our module out into another file as we start to grow.

{{< source "default.nix" >}}

Now we create a module which does a few related things:

- create a `Deployment`
- mount a `ConfigMap` into its pod
- define a `Service`

{{< source "module.nix" >}}

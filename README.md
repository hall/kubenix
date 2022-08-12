# kubenix

Kubernetes resource management with Nix

<p align="center" style="margin: 2em auto;">
  <img src="./docs/logo.svg" alt="nixos logo in kubernetes blue" width="350"/>
</p>

> **WARN**: this is a work in progress, expect breaking changes

## Usage

See [./docs/examples/](./docs/examples/) for now.

<!-- Apply all resources with

    nix run github:hall/kubenix

> **HINT**: run `nix run github:hall/kubenix -- --help` for more commands

A minimal example flake:

```nix
{
  inputs.kubenix = "github:hall/kubenix";
  outputs = {self, ...}@inputs: {
    # nixosConfigurations.hostname = {
    #   modules = [ inputs.kubenix.nixosModule ];
    # };
    kubernetes.cluster.resources.pod.test.spec.containers.nginx.image = "nginx";
  }
}
```

A more complete example config:

```nix
{
  kubernetes = {
    context = "default";
    resources = {};
    helm = {
      releases = {};
    };
    docker = {};
  }
}
``` -->

## Attribution

This project was forked from https://github.com/GTrunSec/kubenix which was forked from https://github.com/xtruder/kubenix.

Logo is a mishmash of the [Kubernetes wheel](https://github.com/kubernetes/kubernetes/blob/master/logo/logo.svg) and the [NixOs snowflake](https://github.com/NixOS/nixos-artwork/blob/master/logo/white.svg).

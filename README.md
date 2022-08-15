# kubenix

Kubernetes resource management with Nix

<p align="center" style="margin: 2em auto;">
  <img src="./docs/logo.svg" alt="nixos logo in kubernetes blue" width="350"/>
</p>

> **WARN**: this is a work in progress, expect breaking changes

## Usage

<!-- Apply all resources with

    nix run github:hall/kubenix . -- apply

> **HINT**: use ` --help` for more commands -->

Create a `default.nix` file:

```nix
{ kubenix ? import (builtins.fetchGit {
  url = "https://github.com/hall/kubenix.git";
  rev = "aa734afc9cf7a5146a7a9d93fd534e81572c8122";
}) }:
(kubenix.evalModules.x86_64-linux {
  module = {kubenix, ...}: {
    imports = with kubenix.modules; [k8s];
    kubernetes.resources.pods.test.spec.containers.nginx.image = "nginx";
  };
}).config.kubernetes.result
```

Then execute `nix-build` to write JSON manifests to `./result`.

<!-- A minimal example flake:

```nix
{
  inputs.kubenix.url = "github:hall/kubenix";
  outputs = {self, ...}@inputs: {
    kubenix = {
      module = { inputs.kubenix, ...}: {
        kubernetes.resources.pods."app" = {
          spec.containers."app" = {
            name = "app";
            image = "nginx";
          };
        };
      }
    }
  }
}
``` -->

<!-- A more complete example config:

```nix
{
  kubernetes = {
    context = "default";
    resources = {};
    helm = {
      releases = {};
    };
  }
}
``` -->

## Attribution

This project was forked from https://github.com/GTrunSec/kubenix which was forked from https://github.com/xtruder/kubenix.

Logo is a mishmash of the [Kubernetes wheel](https://github.com/kubernetes/kubernetes/blob/master/logo/logo.svg) and the [NixOs snowflake](https://github.com/NixOS/nixos-artwork/blob/master/logo/white.svg).

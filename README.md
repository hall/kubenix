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

A minimal example flake (build with `nix build`):

```nix
{
  inputs.kubenix.url = "github:hall/kubenix";
  outputs = {self, kubenix, ... }@inputs: let
    system = "x86_64-linux";
  in {
    packages.${system}.default = (kubenix.evalModules.${system} {
      module = { kubenix, ... }: {
        imports = with kubenix.modules; [k8s];
        kubernetes.resources.pods.example.spec.containers.nginx.image = "nginx";
      };
    }).config.kubernetes.result;
  };
}
```

Or, if you're not using flakes, a `default.nix` file (build with `nix-build`):

```nix
{ kubenix ? import (builtins.fetchGit {
  url = "https://github.com/hall/kubenix.git";
  rev = "aa734afc9cf7a5146a7a9d93fd534e81572c8122";
}) }:
(kubenix.evalModules.x86_64-linux {
  module = {kubenix, ... }: {
    imports = with kubenix.modules; [k8s];
    kubernetes.resources.pods.example.spec.containers.nginx.image = "nginx";
  };
}).config.kubernetes.result
```

Either way the JSON manifests will be written to `./result`.


## Attribution

This project was forked from https://github.com/GTrunSec/kubenix which was forked from https://github.com/xtruder/kubenix.

Logo is a mishmash of the [Kubernetes wheel](https://github.com/kubernetes/kubernetes/blob/master/logo/logo.svg) and the [NixOs snowflake](https://github.com/NixOS/nixos-artwork/blob/master/logo/white.svg).

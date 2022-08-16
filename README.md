# kubenix

Kubernetes resource management with Nix

<p align="center" style="margin: 2em auto;">
  <img src="./docs/logo.svg" alt="nixos logo in kubernetes blue" width="350"/>
</p>

> **WARN**: this is a work in progress, expect breaking changes

## Usage

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

See [./docs/examples](./docs/examples) for more.

## CLI

> **NOTE**: this is a WIP CLI which currently reads the `k8s` attribute on a local flake

Render all resources with

    nix run github:hall/kubenix -- render

> **HINT**: use ` --help` for more commands

### Support

The following table gives a general overview of currently supported functionality.

|        | kubectl | kustomize | helm  | helmfile |
| ------ | :-----: | :-------: | :---: | :------: |
| render |    x    |           | x[^2] |          |
| diff   |         |           |       |          |
| apply  |  x[^1]  |           |       |          |
| hooks  |    -    |     -     |       |          |

[^1]: currently create-only
[^2]: piping rendered helm charts to kubectl is a lossy process (e.g., [hooks](https://helm.sh/docs/topics/charts_hooks/) will not work)

## Attribution

This project was forked from https://github.com/GTrunSec/kubenix which was forked from https://github.com/xtruder/kubenix.

Logo is a mishmash of the [Kubernetes wheel](https://github.com/kubernetes/kubernetes/blob/master/logo/logo.svg) and the [NixOs snowflake](https://github.com/NixOS/nixos-artwork/blob/master/logo/white.svg).

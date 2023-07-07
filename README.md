# kubenix

Kubernetes management with Nix

<p align="center" style="margin: 2em auto;">
  <img src="./docs/static/logo.svg" alt="nixos logo in kubernetes blue" width="350"/>
</p>

> **WARN**: this is a work in progress, expect breaking [changes](./CHANGELOG.md)

## Usage

A minimal example `flake.nix` (build with `nix build`):

```nix
{
  inputs.kubenix.url = "github:hall/kubenix";
  outputs = {self, kubenix, ... }@inputs: let
    system = "x86_64-linux";
  in {
    packages.${system}.default = (kubenix.evalModules.${system} {
      module = { kubenix, ... }: {
        imports = [ kubenix.modules.k8s ];
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
  rev = "main";
}) }:
(kubenix.evalModules.x86_64-linux {
  module = {kubenix, ... }: {
    imports = [ kubenix.modules.k8s ];
    kubernetes.resources.pods.example.spec.containers.nginx.image = "nginx";
  };
}).config.kubernetes.result
```

Either way the JSON manifests will be written to `./result`.

See the [examples](https://kubenix.org/examples/pod) for more.

## CLI

While kubenix is compatible with just about any deployment system, there's a simple builtin CLI which can:

- show a diff, prompt for confirmation, then apply
- prune removed resources
- pipe manifests through [vals](https://github.com/helmfile/vals) for the ability to inject secrets without writing them to the nix store

To configure this, override the default package, passing the arguments of [evalModules](https://nixos.org/manual/nixpkgs/stable/#module-system-lib-evalModules).

```nix
{
  kubenix = inputs.kubenix.packages.${pkgs.system}.default.override {
    module = import ./cluster;
    # optional; pass custom values to the kubenix module
    specialArgs = { flake = self; };
  };
}
```

Then apply the resources with

    nix run '.#kubenix'

which will print a diff and prompt for confirmation:

```diff
diff -N -u -I ' kubenix/hash: ' -I ' generation: ' /tmp/LIVE-2503962153/apps.v1.Deployment.default.home-assistant /tmp/MERGED-231044561/apps.v1.Deployment.default.home-assistant
--- /tmp/LIVE-2503962153/apps.v1.Deployment.default.home-assistant      2023-07-06 23:33:29.841771295 -0400
+++ /tmp/MERGED-231044561/apps.v1.Deployment.default.home-assistant     2023-07-06 23:33:29.842771296 -0400
@@ -43,7 +43,7 @@
     spec:
       automountServiceAccountToken: true
       containers:
-      - image: homeassistant/home-assistant:2023.5
+      - image: homeassistant/home-assistant:2023.6
         imagePullPolicy: IfNotPresent
         livenessProbe:
           failureThreshold: 3
apply? [y/N]:
```

> **HINT**: use ` --help` for more commands

Optionally, write the resources to `./result/manifests.json`:

    nix build '.#kubenix'

## Attribution

This project was forked from [GTrunSec](https://github.com/GTrunSec/kubenix), which was forked from [xtruder](https://github.com/xtruder/kubenix), with commits incorporated from [blaggacao](https://github.com/blaggacao/kubenix).

Logo is a mishmash of the [Kubernetes wheel](https://github.com/kubernetes/kubernetes/blob/master/logo/logo.svg) and the [NixOs snowflake](https://github.com/NixOS/nixos-artwork/blob/master/logo/white.svg).

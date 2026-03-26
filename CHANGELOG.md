# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Breaking

- `docker.copyScript` now produces a binary at `$out/bin/kubenix-push-images` instead of a shell script. Use `nix run .#kubenix.config.docker.copyScript` for a more ergonomic experience.

- Registry URL options have been restructured. Instead of `docker.registry.url` and `docker.images.*.registry`, use:
  - `docker.registry.protocol` (default: `"docker://"`)
  - `docker.registry.host` (default: `""`)
  - `docker.images.*.registry.protocol`
  - `docker.images.*.registry.host`

- `docker.copyScript` now pushes to `docker.images.*.uri` instead of using `imageName` and `imageTag` passthru attributes from the image derivation. This allows dynamic values via `vals` for secrets and runtime variables.

  **Migration:** Import the compatibility module to restore pre-v0.4.0 behavior:

  ```nix
  imports = [ kubenix.modules.docker-image-from-package ];
  ```

  This module:
  - Maps `docker.registry.url` to `docker.registry.host`
  - Maps `docker.images.*.registry` (string) to `docker.images.*.registry.host`
  - Forces `name`/`tag` to use derivation's `imageName`/`imageTag`

  You will see deprecation warnings guiding you to migrate.

- If you don't want `vals` expansion when pushing images (e.g., in air-gapped environments), set `docker.useVals = false`.

### Added

- Image registry, name, and tag can now use `vals` syntax for dynamic/secret expansion at runtime.

- Customizable registry protocol (`docker.registry.protocol` and `docker.images.*.registry.protocol`).

## [0.3.0] - 2024-05-05

### Breaking

- removed generated Kubernetes manifest file (`manifest.json`) from default flake package

  See the [documentation](https://kubenix.org/#usage) how to access the generated Kubernetes manifest file

### Added

- add `optionalHashedNames` to inject hashed names for referencing inside modules
- support `dockerTools.streamLayeredImage`

### Changed

- default `kubernetes.kubeconfig` to `$HOME/.kube/config`
- removed local `kubectl` and `kubernetes` packages in lieu of those from nixpkgs
- pin Bash version of Kubenix CLI script

## [0.2.0] - 2023-07-07

### Breaking

- removed usage of the `helm` CLI within the `kubenix` CLI

  This simplifies design by removing overlapping responsibilities but means extra functionality provided by the `helm` CLI is no longer available; specifically:
  - hooks are no longer ordered (but can still be excluded with `noHooks`)
  - `helm` subcommands (e.g., `list` or `rollback`) will not be able to operate on resources

### Added

- the CLI now prunes resources and performs an interactive diff by default

## [0.1.0] - 2023-07-06

### Added

- initial tagged release

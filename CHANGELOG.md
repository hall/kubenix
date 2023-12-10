# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- add `optionalHashedNames` to inject hashed names for referencing inside modules

### Changed

- default `kubernetes.kubeconfig` to `$HOME/.kube/config`
- removed local `kubectl` and `kubernetes` packages in lieu of those from nixpkgs

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

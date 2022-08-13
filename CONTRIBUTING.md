# Contributing

Thanks for your interest in contributing!
We welcome ideas, code, docs, etc -- just open an issue or MR.

## Setup

This project uses [flakes](https://nixos.wiki/wiki/Flakes) so a development environment can be created with

    nix develop

where you will find a [devshell](https://numtide.github.io/devshell) prompt (which supports [direnv](https://direnv.net/) so a one-time `direnv allow` at the base of the repo should automate the dev shell process).

## Commits

There's no formal commit process at this time.

Do try to format the repo with [treefmt](https://github.com/numtide/treefmt) before submission, however.

    nix fmt

## Kubernetes versions

To support a new Kubernetes version:

- Edit [`./jobs/generators/default.nix`](./jobs/generators/default.nix) and add a block for the version under `k8s`; for example:

  ```nix
  {
    name = "v1.23.nix";
    path = generateK8S "v1.23" (builtins.fetchurl {
      url = "https://github.com/kubernetes/kubernetes/raw/v1.23.0/api/openapi-spec/swagger.json";
      sha256 = "0jivg8nlxka1y7gzqpcxkmbvhcbxynyrxmjn0blky30q5064wx2a";
    });
  }
  ```

- Build and copy the updated specs to [`modules/generated/`](./modules/generated/)

      nix build '.#jobs.x86_64-linux.generators.k8s'
      cp ./result/* modules/generated/

- Add the version in [`./modules/k8s.nix`](./modules/k8s.nix) under `options.kubernetes.version.type`
- Add a new check in [`./flake.nix`](./flake.nix) (e.g., `tests-k8s-1_23`)

## Tests

Tests are executed through GitHub actions; see the [workflow definition](../kubenix/.github/workflows/ci.yml) for commands.

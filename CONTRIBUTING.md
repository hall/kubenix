# Contributing

Thanks for your interest in contributing!
We welcome ideas, code, docs, etc -- just open an issue or MR.

## Setup

This project uses [flakes](https://nixos.wiki/wiki/Flakes) so a development environment can be created with

    nix develop

> **NOTE**: there's also support for [direnv](https://direnv.net/) to automate the dev shell process

## Commits

There's no formal commit process at this time.

Do try to format the repo with [treefmt](https://github.com/numtide/treefmt) before submission, however.

    nix fmt

## Kubernetes versions

To support a new Kubernetes version:

- Edit [`./versions.nix`](./versions.nix) and add a new attribute for the version; for example:

  ```nix
  {
    "1.23.0" = "sha256:0jivg8nlxka1y7gzqpcxkmbvhcbxynyrxmjn0blky30q5064wx2a";
  }
  ```

- Build and copy the updated specs to [`modules/generated/`](./modules/generated/) with

      nix run '.#generate'

## Tests

Tests are executed through GitHub actions; see the [workflow definition](../kubenix/.github/workflows/ci.yml) for commands.

## Docs

Build and serve the static site

    nix run '.#docs' serve

which will be available at <http://localhost:1313>.

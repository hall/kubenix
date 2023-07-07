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

## Releases

User-facing changes should be reflected in [`CHANGELOG.md`](./CHANGELOG.md).
When a new entry is added to the default branch, a new release will automatically be tagged.

## Kubernetes versions

To support a new Kubernetes version:

- Edit [`./versions.nix`](./versions.nix) and add a new attribute for the version; for example:

  ```nix
  {
    "1.23.0" = "sha256:0jivg8nlxka1y7gzqpcxkmbvhcbxynyrxmjn0blky30q5064wx2a";
  }
  ```

- Build the updated specs to [`modules/generated/`](./modules/generated/) with

      nix run '.#generate'

## Tests

Tests are executed through GitHub actions; see the [workflow definition](../kubenix/.github/workflows/ci.yml) for commands.

## Docs

Build and serve the static site

    nix run '.#docs' serve

which will be available at <http://localhost:1313>.

### Examples

Examples are written at [./docs/content/examples](./docs/content/examples) and are (or will, really) also used as tests which can be executed with

    nix flake check

In general, that just means: don't directly put nix snippets into a markdown doc; instead use the shortcode provided to pull them in so they don't have to be parsed out for testing.

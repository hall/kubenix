---
weight: 30
---

Instead of deploying a 3rd party image, we can build our own.

We rely on the upstream [`dockerTools`](https://github.com/NixOs/nixpkgs/tree/master/pkgs/built-support/docker) package here.
Specifically, we can use the `buildImage` function to define our image:

{{< source "image.nix" >}}

Then we can import this package into our `docker` module:

{{< source "default.nix" >}}

Now build the image with

```sh
nix build -f . --json config.docker.export
```

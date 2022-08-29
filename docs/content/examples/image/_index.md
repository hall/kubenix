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

Render the generated manifests again and see that it now refers to the newly built tag:

```json
{
  "apiVersion": "v1",
  "items": [
    {
      "apiVersion": "v1",
      "kind": "Pod",
      "metadata": {
        "annotations": {
          "kubenix/k8s-version": "1.24",
          "kubenix/project-name": "kubenix"
        },
        "labels": {
          "kubenix/hash": "ac7e4794c3d37f0884e4512a680a30d20e1d6454"
        },
        "name": "example"
      },
      "spec": {
        "containers": [
          {
            "image": "docker.somewhere.io/nginx:w7c63alk7kynqh2mqnzxy9n1iqgdc93s",
            "name": "custom"
          }
        ]
      }
    }
  ],
  "kind": "List",
  "labels": {
    "kubenix/hash": "ac7e4794c3d37f0884e4512a680a30d20e1d6454",
    "kubenix/k8s-version": "1.24",
    "kubenix/project-name": "kubenix"
  }
}
```

Of course, to actually deploy, we need to push the image to our registry. The script defined at {{< option "docker.copyScript" >}} does just that.

```sh
$(nix build -f . --json config.docker.copyScript | jq -r '.[].outputs.out')
```

 <!-- TODO: can we make that `nix run -f . config.docker.copyScript` ? -->

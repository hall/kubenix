---
title: "Pod"
weight: 10
---

The simplest, but not incredibly useful, example is likely deploying a bare pod.

Which we can do with the `kubernetes.resources.pods` option:

{{< source "default.nix" >}}

Here, `example` is an arbitrary string which identifies the pod (just as `ex` identifies a container within the pod).

{{< hint info >}}
**NOTE**

The format under {{< option "kubernetes.resources" true >}} largely mirrors that of the [Kubernetes API](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/) which can generally be explored with `kubectl`; e.g.

```sh
kubectl explain pod.spec.containers
```

However, our format uses the plural form and injects resource names where appropriate.
{{< /hint >}}

Create a json manifest with:

```sh
nix eval -f . --json config.kubernetes.generated
```

which should output something like this:

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
          "kubenix/hash": "6e6ccbb6787f9b600737f8882d2487eeef84af9f"
        },
        "name": "example"
      },
      "spec": {
        "containers": [
          {
            "image": "nginx",
            "name": "ex"
          }
        ]
      }
    }
  ],
  "kind": "List",
  "labels": {
    "kubenix/hash": "6e6ccbb6787f9b600737f8882d2487eeef84af9f",
    "kubenix/k8s-version": "1.24",
    "kubenix/project-name": "kubenix"
  }
}
```

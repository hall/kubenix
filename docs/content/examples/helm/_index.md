---
title: "Helm"
---

To define a Helm release, use the {{< option "kubernetes.helm.releases" >}} option.

{{< source "default.nix" >}}

Fetch and render the chart just as we did with plain manifests:

```sh
nix eval -f . --json config.kubernetes.generated
```

## patching

A common issue with Helm charts is the need to template everything under the sun.
Kubenix solves this issue by merging configuration during evaluation.

For example, to patch the deployment created by the release above:

```nix
{
  # define a resource with the same name
  kubernetes.resources.deployments.nginx = {
    # be sure to match the corresponding namespace as well
    metadata.namespace = "default";
    # here we can configure anything and are no longer bound by `values.yaml`
    spec.template.spec.containers.nginx.env = [{
      name = "MY_VARIABLE";
      value = "100";
    }];
  };
}
```

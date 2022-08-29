To define a helm release, use the {{< option "kubernetes.helm.releases" >}} option.

{{< source "default.nix" >}}

Fetch and render the chart just as we did with plain manifests:

```sh
nix eval -f . --json config.kubernetes.generated
```

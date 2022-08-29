To define a helm release, use the {{< option "kubernetes.helm.releases" >}} option.

{{< source "default.nix" >}}

Fetch and render the chart:

```sh
nix eval -f . config.kubernetes.generated
```

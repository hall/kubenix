The k3s project supports [automatic resource deployment](https://docs.k3s.io/installation/packaged-components#auto-deploying-manifests-addons) of files in the `/var/lib/rancher/k3s/server/manifests` directory.

As such, on a server node, we can write kubenix's output there.

```nix
{
  # let's write `resultYAML` to an arbitrary file under `/etc`
  environment.etc."kubenix.yaml".source = 
  (kubenix.evalModules.x86_64-linux {
    module = { kubenix, ... }: {
      imports = [ kubenix.modules.k8s ];
      kubernetes.resources.pods.example.spec.containers.example.image = "nginx";
    };
  }).config.kubernetes.resultYAML;

  # now we can link our file into the appropriate directory
  # and k3s will handle the rest
  system.activationScripts.kubenix.text = ''
    ln -sf /etc/kubenix.yaml /var/lib/rancher/k3s/server/manifests/kubenix.yaml
  '';
}
```
{{< hint danger >}}
**WARN**: this will write all manifests to the nix store and is therefore not suitable for inline sensitive data.
{{< /hint >}}

{{< hint info >}}
**NOTE**: k3s will not delete resources if files are removed.
{{< /hint >}}

A good runtime secret option (thus avoiding exposing them in the nix store) is loading values with [vals](https://github.com/variantdev/vals).
A minimal example, using the file provider, might look like

{{< source "default.nix" >}}

{{< hint info >}}
**NOTE**: The creation of `/path/to/secret` is out of scope but we recommend checking out one of the [secret managing schemes](https://nixos.wiki/wiki/Comparison_of_secret_managing_schemes).
{{< /hint >}}

Then it's up to you when and where to apply from with something along the lines of:

```nix
pkgs.writeShellScript "apply" ''
  cat /path/to/manifests | ${pkgs.vals}/bin/vals eval | ${pkgs.kubectl}/bin/kubectl -f -
''
```

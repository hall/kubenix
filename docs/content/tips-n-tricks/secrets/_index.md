As the nix store is world-readable, we want to avoid writing secrets during evaluation.

We can roughly break the entire process, from nix to kube, down to

    eval -> deploy -> run

## eval time

This is the process of taking nix configuration and generating a JSON manifest.

The generated manifest is written to the nix store;
so inlining (unencrypted) secrets is entirely possible but not ideal.

## deploy time

The simplest option is to inject secrets during deploy; that is, after manifests have been generated but prior to running `kubectl apply` (or equivalent).

### example

We can pipe manifests through [vals](https://github.com/variantdev/vals) prior to apply.
Such that using the file provider might look like

{{< source "default.nix" >}}

{{< hint info >}}
**NOTE**: the creation of `/path/to/secret` is out of scope but we recommend checking out one of the [secret managing schemes](https://nixos.wiki/wiki/Comparison_of_secret_managing_schemes)
{{< /hint >}}

Then the apply might look something like

```nix
pkgs.writeShellScript "apply" ''
  cat manifest.json | ${pkgs.vals}/bin/vals eval | ${pkgs.kubectl}/bin/kubectl -f -
''
```

{{< hint info >}}
**NOTE**: the builtin `kubenix` CLI uses this approach so it's not _necessary_ to implement yourself
{{< /hint >}}


## runtime

A more robust option is to resolve secrets from _within_ the cluster itself.

This can be done with tools that either

- reference external sources 

    similar to the deploy time example; instead, resolving secrets with a controller running inside the cluster (e.g., [external-secrets](https://github.com/external-secrets/external-secrets))

- decrypt inline secrets

    values can be decrypted by a controller within the cluster itself (e.g., [sealed-secrets](https://github.com/bitnami-labs/sealed-secrets)) or using external keys (e.g., [sops](https://github.com/getsops/sops))

    
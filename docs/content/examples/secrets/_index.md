Secrets management requires some extra care as we want to prevent values from
ending up in the, world-readable, nix store.

{{< hint "warning" >}}
**WARNING**

The kubenix secrets story is incomplete. Do not trust it -- it has not been tested.
{{< /hint >}}

The easiest approach is to avoid writing to the store altogether with `nix eval` instead of `nix build`.
This isn't a long-term device and we'll explore integrations with other tools soon(TM).

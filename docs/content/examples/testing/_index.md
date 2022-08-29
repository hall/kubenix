Testing is still very much in flux but here's a rough example.

{{< source "default.nix" >}}

Where we've defined a might look like:

{{< source "test.nix" >}}

Execute with

```sh
nix eval -f . config.testing.success
```

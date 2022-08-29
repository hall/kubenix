Testing is still very much in flux but here's a rough example.

{{< source "default.nix" >}}

Where we've defined a test here:

{{< source "test.nix" >}}

Execute the test with

```sh
nix eval -f . config.testing.success
```

We support runtime secret (or config) value loading with [vals](https://github.com/variantdev/vals). A minimal example, using the file provider, might look like

{{< source "default.nix" >}}

The creation of `/path/to/secret` is out of scope but we recommend checking out one of [the many nix secrets management tools](https://nixos.wiki/wiki/Comparison_of_secret_managing_schemes).

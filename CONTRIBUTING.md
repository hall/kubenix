# Contributing

## Kubernetes versions

Edit [`./jobs/generators/default.nix`](./jobs/generators/default.nix) and add a block for the new version of Kubernetes in `generate.k8s`. For example:

```nix
{
  name = "v1.23.nix";
  path = generateK8S "v1.23" (builtins.fetchurl {
    url = "https://github.com/kubernetes/kubernetes/raw/v1.23.0/api/openapi-spec/swagger.json";
    sha256 = "0jivg8nlxka1y7gzqpcxkmbvhcbxynyrxmjn0blky30q5064wx2a";
  });
}
```

Then build and copy all specs to [`modules/generated/`](./modules/generated/):

    nix build '.#jobs.x86_64-linux.generators.k8s'
    cp ./result/* modules/generated/

Now add the version in [`./modules/k8s.nix`](./modules/k8s.nix) under `options.kubernetes.version.type` as well as a new check in [`./flake.nix`](./flake.nix) (e.g., `tests-k8s-1_23`).

## Tests

Tests are executed through GitHub actions; see the [workflow definition](../kubenix/.github/workflows/ci.yml) for commands.

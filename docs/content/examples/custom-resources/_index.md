---
title: "Custom Resources"
linkTitle: "Custom Resources"
weight: 80
description: >
  Defining and using Custom Resource Definitions (CRDs).
---

The `kubernetes.customTypes` option allows you to register Custom Resource Definitions (CRDs) with Kubenix. This enables type-safe definition of custom resources using Nix options.

## Defining Custom Types

To register a CRD, add an entry to the `kubernetes.customTypes` list. Each entry defines the Group, Version, Kind, and the Nix module that describes the schema of the resource.

## Example

{{< file "module.nix" >}}

## Instantiation

Once a custom type is defined, you can instantiate resources under `kubernetes.resources.<attrName>`. In the example above, we set `attrName = "crontabs"`, so we can define resources under `kubernetes.resources.crontabs`.

The generated JSON output will look something like this:

```json
{
  "apiVersion": "stable.example.com/v1",
  "kind": "CronTab",
  "metadata": {
    "name": "my-new-cron-object",
     ...
  },
  "spec": {
    "cronSpec": "* * * * */5",
    "image": "my-awesome-cron-image",
    "replicas": 1
  }
}
```

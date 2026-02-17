---
title: "Namespaces"
---

This example demonstrates the use of kubenix submodules, which are built atop of nixos submodule system, to create resources in multiple namespaces.

{{< source "default.nix" >}}

Here's a definition of a submodule.

{{< source "namespaced.nix" >}}

And here's how it can be used.

{{< source "module.nix" >}}

{ kubenix ? import ../../../.. }:
kubenix.evalModules.x86_64-linux {
   module = {kubenix, ...}: {
     imports = [./module.nix];

     kubenix.project = "example";
     docker.registry.url = "docker.io/gatehub";
     kubernetes.version = "1.24";
   };
 }

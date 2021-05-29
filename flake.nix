{
  description = "Kubernetes resource builder using nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
    devshell-flake.url = "github:numtide/devshell";
  };

  outputs = { self, nixpkgs, flake-utils, devshell-flake }:

    (flake-utils.lib.eachDefaultSystem (system:
      let

        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            self.overlay
            devshell-flake.overlay
          ];
          config = { allowUnsupportedSystem = true; };
        };

      in
      {

        devShell = with pkgs; devshell.mkShell
          { imports = [ (devshell.importTOML ./devshell.toml) ]; };

        packages = flake-utils.lib.flattenTree {
          inherit (pkgs) kubernetes kubectl;
        };

        defaultPackage = pkgs.kubenix;

        jobs = import ./jobs { inherit pkgs; };

      }
    ))

    //

    {
      modules = import ./src/modules;
      overlay = final: prev: {
        kubenix = prev.callPackage ./src/kubenix.nix { };
        # up to date versions of their nixpkgs equivalents
        kubernetes = prev.callPackage ./pkgs/applications/networking/cluster/kubernetes
          { };
        kubectl = prev.callPackage ./pkgs/applications/networking/cluster/kubectl { };
      };
    };
}

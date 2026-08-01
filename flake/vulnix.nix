{ ... }:
{
  perSystem = { config, lib, pkgs, ... }:
    let
      # vulnix reads .drv files, so instantiating is enough; asking for the
      # outputs would also build them, and mkShell derivations shouldn't be built.
      drvPath = package: builtins.unsafeDiscardOutputDependency package.drvPath;

      # --requisites (vulnix's default) walks the build-time closure, which
      # subsumes the runtime closure of each of these.
      scanTargets = map drvPath [
        config.checks.packages
        config.devShells.default
      ];

      # After bumping nixpkgs, re-triage and review the diff with
      #   nix run .#vulnix -- --write-whitelist flake/vulnix-whitelist.toml
      #
      # --write-whitelist accepts every current match, so it silently absolves
      # new CVEs unless a human reads what it added.
      whitelist = ./vulnix-whitelist.toml;
    in
    {
      apps.vulnix.program = pkgs.writeShellApplication {
        name = "vulnix";
        runtimeInputs = [ pkgs.vulnix ];
        text = ''
          exec vulnix \
            --whitelist ${whitelist} \
            ${lib.concatStringsSep " " scanTargets} \
            "$@"
        '';
      };
    };
}

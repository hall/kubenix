{ inputs, ... }:
{
  # Wires up perSystem `formatter` and the `checks.formatting` check.
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem.treefmt = {
    projectRootFile = "flake.nix";
    programs = {
      nixpkgs-fmt.enable = true;
      black.enable = true;
      prettier.enable = true;
      shfmt.enable = true;
    };
    settings.global.excludes = [
      "docs/themes/*"
      "docs/layouts/*"
      "modules/generated/*"
    ];
  };
}

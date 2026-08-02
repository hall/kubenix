{ inputs, ... }:
{
  imports = [ inputs.devshell.flakeModule ];

  perSystem = { pkgs, ... }: {
    devshells.default = {
      devshell.name = "kubenix";

      packages = with pkgs; [
        dive
        k9s
        k3d
        kubie
      ];
    };
  };
}

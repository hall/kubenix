{ ... }:
{
  perSystem = { pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        dive
        k9s
        k3d
        kubie
      ];
    };
  };
}

{
  pkgs,
  inputs,
}:
pkgs.devshell.mkShell {
  imports = [(pkgs.devshell.importTOML ./devshell.toml)];

  packages = [
    pkgs.shfmt
    pkgs.nodePackages.prettier
    pkgs.nodePackages.prettier-plugin-toml
    pkgs.alejandra
  ];
  commands = [
    {
      package = pkgs.treefmt;
    }
  ];
  devshell.startup.nodejs-setuphook = pkgs.lib.stringsWithDeps.noDepEntry ''
    export NODE_PATH=${pkgs.nodePackages.prettier-plugin-toml}/lib/node_modules:$NODE_PATH
  '';
}

{
  pkgs,
  inputs,
}:
pkgs.devshell.mkShell {
  imports = [(pkgs.devshell.importTOML ./devshell.toml)];
}

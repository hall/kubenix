{ config
, lib
, ...
}:
let
  cfg = config.docker;
in
{
  imports = [ ./docker.nix ];

  options.docker.registry.url = lib.mkOption {
    description = "DEPRECATED: Use docker.registry.host instead";
    type = lib.types.str;
    default = "";
  };

  config.docker.registry.host = lib.mkIf (cfg.registry.url != "") cfg.registry.url;
}

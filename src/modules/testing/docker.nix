{ config, lib, pkgs, ... }:

with lib;
with import ../../lib/docker { inherit lib pkgs; };
let
  testing = config.testing;

  allImages = unique (flatten (map (t: t.evaled.config.docker.export or [ ]) testing.tests));

  cfg = config.testing.docker;

in
{
  options.testing.docker = {
    registryUrl = mkOption {
      description = "Docker registry url";
      type = types.str;
    };

    images = mkOption {
      description = "List of images to export";
      type = types.listOf types.package;
    };

    copyScript = mkOption {
      description = "Script to copy images to registry";
      type = types.package;
    };
  };

  config.testing.docker = {
    images = allImages;

    copyScript = copyDockerImages {
      images = cfg.images;
      dest = "docker://" + cfg.registryUrl;
    };
  };

  config.testing.defaults = [{
    features = [ "docker" ];
    default = {
      docker.registry.url = cfg.registryUrl;
    };
  }];
}

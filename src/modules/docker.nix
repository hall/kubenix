{ config, lib, pkgs, docker, ... }:

with lib;
let
  cfg = config.docker;
in
{
  imports = [ ./base.nix ];

  options.docker = {
    registry.url = mkOption {
      description = "Default registry url where images are published";
      type = types.str;
      default = "";
    };

    images = mkOption {
      description = "Attribute set of docker images that should be published";
      type = types.attrsOf (types.submodule ({ name, config, ... }: {
        options = {
          image = mkOption {
            description = "Docker image to publish";
            type = types.nullOr types.package;
            default = null;
          };

          name = mkOption {
            description = "Desired docker image name";
            type = types.str;
            default = builtins.unsafeDiscardStringContext config.image.imageName;
          };

          tag = mkOption {
            description = "Desired docker image tag";
            type = types.str;
            default = builtins.unsafeDiscardStringContext config.image.imageTag;
          };

          registry = mkOption {
            description = "Docker registry url where image is published";
            type = types.str;
            default = cfg.registry.url;
          };

          path = mkOption {
            description = "Full docker image path";
            type = types.str;
            default =
              if config.registry != ""
              then "${config.registry}/${config.name}:${config.tag}"
              else "${config.name}:${config.tag}";
          };
        };
      }));
      default = { };
    };

    export = mkOption {
      description = "List of images to export";
      type = types.listOf types.package;
      default = [ ];
    };

    copyScript = mkOption {
      description = "Image copy script";
      type = types.package;
      default = docker.copyDockerImages {
        dest = "docker://${cfg.registry.url}";
        images = cfg.export;
      };
    };
  };

  config = {
    # define docker feature
    _m.features = [ "docker" ];

    # propagate docker options if docker feature is enabled
    _m.propagate = [{
      features = [ "docker" ];
      module = { config, name, ... }: {
        # propagate registry options
        docker.registry = cfg.registry;
      };
    }];

    # pass docker library as param
    _module.args.docker = import ../lib/docker { inherit lib pkgs; };

    # list of exported docker images
    docker.export = mapAttrsToList (_: i: i.image)
      (filterAttrs (_: i: i.registry != null) config.docker.images);
  };
}

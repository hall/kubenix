{ config, lib, pkgs, docker, ... }:
with lib; let
  cfg = config.docker;
  protocols = [
    "containers-storage:"
    "dir:"
    "docker://"
    "docker-archive:"
    "docker-daemon:"
    "oci:"
    "oci-archive:"
  ];
in
{
  imports = [ ./base.nix ];

  options.docker = {
    registry = {
      protocol = mkOption {
        description = "Default registry protocol where images are published";
        type = types.enum protocols;
        default = "docker://";
      };

      host = mkOption {
        description = "Default registry host where images are published";
        type = types.str;
        default = "";
      };
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
            default =
              if config.image != null
              then builtins.unsafeDiscardStringContext config.image.imageName
              else "";
          };

          tag = mkOption {
            description = "Desired docker image tag";
            type = types.str;
            default =
              if config.image != null
              then builtins.unsafeDiscardStringContext config.image.imageTag
              else "";
          };

          registry = {
            protocol = mkOption {
              description = "Default registry protocol where this image is published";
              type = types.enum protocols;
              default = cfg.registry.protocol;
            };

            host = mkOption {
              description = "Default registry host where this image is published";
              type = types.str;
              default = cfg.registry.host;
            };
          };

          path = mkOption {
            description = "Full docker image path";
            type = types.str;
            default = lib.concatStrings [
              (if config.registry.host == "" then "" else "${config.registry.host}/")
              config.name
              ":"
              config.tag
            ];
          };

          uri = mkOption {
            description = "Full docker image URI";
            type = types.str;
            default = lib.concatStrings [
              config.registry.protocol
              config.path
            ];
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

    useVals = mkOption {
      description = "Whether to use vals for expanding image URIs at runtime in the copy script. Disable for air-gapped environments or when URIs contain no dynamic values.";
      type = types.bool;
      default = true;
    };

    copyScriptArgs = mkOption {
      description = "Additional arguments to pass to skopeo copy in the copy script";
      type = types.str;
      default = "";
    };

    copyScript = mkOption {
      description = "Image copy script";
      type = types.package;
      default = docker.copyDockerImages {
        inherit (cfg) useVals;
        args = cfg.copyScriptArgs;
        images = builtins.attrValues cfg.images;
      };
    };
  };

  config = {
    # define docker feature
    _m.features = [ "docker" ];

    # propagate docker options if docker feature is enabled
    _m.propagate = [{
      features = [ "docker" ];
      module = _: {
        # propagate registry options
        docker.registry = cfg.registry;
      };
    }];

    # pass docker library as param
    _module.args.docker = import ../lib/docker { inherit lib pkgs; };

    # list of exported docker images
    docker.export = mapAttrsToList (_: i: i.image)
      (filterAttrs (_: i: i.image != null) config.docker.images);
  };
}

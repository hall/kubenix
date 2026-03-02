{ lib
, pkgs
,
}: {
  copyDockerImages =
    { images
    , args ? ""
    ,
    }:
    pkgs.writeShellApplication {
      name = "kubenix-push-images";
      excludeShellChecks = [
        "SC2005"
        "SC2016"
        "SC2089"
        "SC2090"
      ];
      runtimeEnv = {
        copyOne = ''
        '';
      };
      runtimeInputs = [
        pkgs.gzip
        pkgs.skopeo
        pkgs.vals
      ];
      text =
        lib.concatMapStrings
          ({ image
           , uri
           , prefix ? lib.optionalString (image.isExe or false) "${image} | gzip --fast |"
           , src ? if image.isExe or false
             then "/dev/stdin"
             else image
           , ...
           }: ''
            echo "copying '${image.imageName}:${image.imageTag}' to '$(vals get ${lib.escapeShellArg uri})'"
            ${prefix} skopeo copy ${args} "$@" docker-archive:${lib.escapeShellArg src} "$(vals get ${lib.escapeShellArg uri})"
          '')
          images;
    };
}

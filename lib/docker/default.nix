{ lib
, pkgs
,
}: {
  copyDockerImages =
    { images
    , args ? ""
    , useVals ? true
    ,
    }:
    pkgs.writeShellApplication {
      name = "kubenix-push-images";
      excludeShellChecks = [
        "SC2005"
        "SC2016"
        "SC2046"
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
      ] ++ lib.optionals useVals [ pkgs.vals ];
      text =
        lib.concatMapStrings
          ({ image
           , uri
           , prefix ? lib.optionalString (image.isExe or false) "${image} | gzip --fast |"
           , src ? if image.isExe or false
             then "/dev/stdin"
             else image
           , ...
           }:
            let
              resolvedUri = if useVals then "$(vals get ${lib.escapeShellArg uri})" else lib.escapeShellArg uri;
            in
            ''
              echo "copying '${image.imageName}:${image.imageTag}' to '${resolvedUri}'"
              ${prefix} skopeo copy ${args} "$@" docker-archive:${lib.escapeShellArg src} ${resolvedUri}
            '')
          images;
    };
}

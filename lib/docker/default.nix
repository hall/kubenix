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
          (imgSpec:
            let
              inherit (imgSpec) image uri;
              imagePath = builtins.toString image;
              # In newer nixpkgs, buildLayeredImage propagates isExe = true from
              # its internal streamLayeredImage passthru, even though its output is
              # a tarball. Guard against this by checking the output path suffix.
              isTarball =
                lib.hasSuffix ".tar.gz" imagePath
                || lib.hasSuffix ".tar.zst" imagePath
                || lib.hasSuffix ".tar" imagePath;
              isExe = (image.isExe or false) && !isTarball;
              prefix = imgSpec.prefix or (lib.optionalString isExe "${image} | gzip --fast |");
              src = imgSpec.src or (if isExe then "/dev/stdin" else image);
              resolvedUri = if useVals then "$(vals get ${lib.escapeShellArg uri})" else lib.escapeShellArg uri;
            in
            ''
              echo "copying '${image.imageName}:${image.imageTag}' to '${resolvedUri}'"
              ${prefix} skopeo copy ${args} "$@" docker-archive:${lib.escapeShellArg src} ${resolvedUri}
            '')
          images;
    };
}

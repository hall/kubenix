{ lib, pkgs }:
with lib; {
  copyDockerImages = { images, dest, args ? "" }:
    pkgs.writeScript "copy-docker-images.sh" (concatMapStrings
      (image:
        let
          prefix = optionalString (image.isExe or false) "${image} | ${pkgs.gzip}/bin/gzip --fast |";
          src = if image.isExe or false then "/dev/stdin" else image;
        in
        ''
          #!${pkgs.runtimeShell}

          set -e

          echo "copying '${image.imageName}:${image.imageTag}' to '${dest}/${image.imageName}:${image.imageTag}'"
          ${prefix} ${pkgs.skopeo}/bin/skopeo copy ${args} $@ docker-archive:${src} ${dest}/${image.imageName}:${image.imageTag}
        '')
      images);
}

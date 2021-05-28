{ lib, pkgs }:

with lib;

{
  copyDockerImages = { images, dest, args ? "" }:
    pkgs.writeScript "copy-docker-images.sh" (concatMapStrings
      (image: ''
        #!${pkgs.runtimeShell}

        set -e

        echo "copying '${image.imageName}:${image.imageTag}' to '${dest}/${image.imageName}:${image.imageTag}'"
        ${pkgs.skopeo}/bin/skopeo copy ${args} $@ docker-archive:${image} ${dest}/${image.imageName}:${image.imageTag}
      '')
      images);
}

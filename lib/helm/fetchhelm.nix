{
  stdenvNoCC,
  lib,
  kubernetes-helm,
  cacert,
}: let
  cleanName = name: lib.replaceStrings ["/"] ["-"] name;
in
  {
    # name of the chart
    chart,
    # chart url to fetch from custom location
    chartUrl ? null,
    # version of the chart
    version ? null,
    # chart hash
    sha256,
    # whether to extract chart
    untar ? true,
    # use custom charts repo
    repo ? null,
    # pass --verify to helm chart
    verify ? false,
    # pass --devel to helm chart
    devel ? false,
  }:
    stdenvNoCC.mkDerivation {
      name = "${cleanName chart}-${
        if version == null
        then "dev"
        else version
      }";

      buildCommand = ''
        export HOME="$PWD"
        echo "adding helm repo"
        ${
          if repo == null
          then ""
          else "helm repo add repository ${repo}"
        }
        echo "fetching helm chart"
        helm fetch -d ./chart \
          ${
          if untar
          then "--untar"
          else ""
        } \
          ${
          if version == null
          then ""
          else "--version ${version}"
        } \
          ${
          if devel
          then "--devel"
          else ""
        } \
          ${
          if verify
          then "--verify"
          else ""
        } \
          ${
          if chartUrl == null
          then
            (
              if repo == null
              then chart
              else "repository/${chart}"
            )
          else chartUrl
        }
        cp -r chart/*/ $out
      '';
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = sha256;
      nativeBuildInputs = [kubernetes-helm cacert];
    }

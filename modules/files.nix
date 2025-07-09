{ config, lib, pkgs, ... }:
with lib; let
  cfg = config.kubernetes.files;

  importMultiDocumentYAML = path:
    importJSON (pkgs.runCommand "yaml-to-json" { } ''
      ${pkgs.yq}/bin/yq -Scs . ${path} > $out
    '');

  parseApiVersion = apiVersion:
    let
      splitted = splitString "/" apiVersion;
    in
    {
      group =
        if length splitted == 1
        then "core"
        else head splitted;
      version = last splitted;
    };
in
{
  options.kubernetes.files = mkOption {
    description = "Attribute set of YAML files to import";
    type = types.attrsOf (types.submodule ({ config, name, ... }: {
      options = {
        name = mkOption {
          description = "Name of the file";
          type = types.str;
          default = name;
        };

        src = mkOption {
          description = "File to use";
          type = types.package;
        };

        overrides = mkOption {
          description = "Overrides to apply to all of the file's resources";
          type = types.listOf types.unspecified;
          default = [ ];
        };

        objects = mkOption {
          description = "Parsed kubernetes objects";
          type = types.listOf types.attrs;
          default = [ ];
        };
      };
      config.objects = importMultiDocumentYAML config.src;
    }));
    default = { };
  };

  config = {
    kubernetes.api.resources = mkMerge (flatten (mapAttrsToList
      (_: file: map
        (object:
          let
            apiVersion = parseApiVersion object.apiVersion;
            inherit (object.metadata) name;
          in
          {
            "${apiVersion.group}"."${apiVersion.version}".${object.kind}."${name}" = mkMerge ([
              object
            ]
            ++ file.overrides);
          })
        file.objects
      )
      cfg));
  };
}

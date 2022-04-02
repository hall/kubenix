{
  lib,
  pkgs,
}:
with lib; let
  self = {
    importYAML = path:
      importJSON (pkgs.runCommand "yaml-to-json" {} ''
        ${pkgs.remarshal}/bin/remarshal -i ${path} -if yaml -of json > $out
      '');

    toYAML = config:
      builtins.readFile (pkgs.runCommand "to-yaml" {} ''
        ${pkgs.remarshal}/bin/remarshal -i ${pkgs.writeText "to-json" (builtins.toJSON config)} -if json -of yaml > $out
      '');

    toMultiDocumentYaml = name: documents:
      pkgs.runCommand name {}
      (concatMapStringsSep "\necho --- >> $out\n"
        (
          d: "${pkgs.remarshal}/bin/remarshal -i ${builtins.toFile "doc" (builtins.toJSON d)} -if json -of yaml >> $out"
        )
        documents);

    toBase64 = value:
      builtins.readFile
      (pkgs.runCommand "value-to-b64" {} "echo -n '${value}' | ${pkgs.coreutils}/bin/base64 -w0 > $out");

    exp = base: exp: foldr (_value: acc: acc * base) 1 (range 1 exp);

    octalToDecimal = value:
      (foldr
        (char: acc: {
          i = acc.i + 1;
          value = acc.value + (toInt char) * (self.exp 8 acc.i);
        })
        {
          i = 0;
          value = 0;
        }
        (stringToCharacters value))
      .value;
  };
in
  self

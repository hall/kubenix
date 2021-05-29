{ lib }:

with lib;

rec {
  # TODO: refactor with mkOptionType
  mkSecretOption = { description ? "", default ? { }, allowNull ? true }: mkOption {
    inherit description;
    type = (if allowNull then types.nullOr else id) (types.submodule {
      options = {
        name = mkOption ({
          description = "Name of the secret where secret is stored";
          type = types.str;
          default = default.name;
        } // (optionalAttrs (default ? "name") {
          default = default.name;
        }));

        key = mkOption ({
          description = "Name of the key where secret is stored";
          type = types.str;
        } // (optionalAttrs (default ? "key") {
          default = default.key;
        }));
      };
    });
    default = if default == null then null else { };
  };

  secretToEnv = value: {
    valueFrom.secretKeyRef = {
      inherit (value) name key;
    };
  };

  # Creates kubernetes list from a list of kubernetes objects
  mkList = { items, labels ? { } }: {
    kind = "List";
    apiVersion = "v1";

    inherit items labels;
  };

  # Creates hashed kubernetes list from a list of kubernetes objects
  mkHashedList = { items, labels ? { } }:
    let
      hash = builtins.hashString "sha1" (builtins.toJSON items);

      labeledItems = map
        (item: recursiveUpdate item {
          metadata.labels."kubenix/hash" = hash;
        })
        items;

    in
    mkList {
      items = labeledItems;
      labels = {
        "kubenix/hash" = hash;
      } // labels;
    };

  toBase64 = lib.toBase64;
  octalToDecimal = lib.octalToDecimal;
}

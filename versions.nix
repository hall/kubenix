let
  full = {
    "1.19.10" = "sha256-ZXxonUAUxRK6rhTgK62ytTdDKCuOoWPwxJmktiKgcJc=";
    "1.20.6" = "sha256-xzVOarQDSomHMimpt8H6MfpiQrLl9am2fDvk/GfLkDw=";
    "1.21.0" = "sha256-EoqYTbtaTlzs7vneoNtXUmdnjTM/U+1gYwCiEy0lOcw=";
    "1.23.0" = "sha256:0jivg8nlxka1y7gzqpcxkmbvhcbxynyrxmjn0blky30q5064wx2a";
    "1.24.0" = "sha256:0fp5hbqk2q0imrfi4mwp1ia0bmn0xnl6hcr07y52q2cp41pmfhqd";
  };
in {
  inherit full;
  # sorted list of major.minor version numbers
  # NOTE: avoiding pulling in lib here (not for any good reason)
  versions =
    map (v: let
      arr = builtins.splitVersion v;
    in (
      builtins.concatStringsSep "."
      [
        (builtins.elemAt arr 0)
        (builtins.elemAt arr 1)
      ]
    ))
    (builtins.attrNames full);
}

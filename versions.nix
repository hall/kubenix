let
  full = {
    # https://kubernetes.io/releases/patch-releases
    "1.19.16" = "sha256:15vhl0ibd94rqkq678cf5cl46dxmnanjpq0lmsx15i8l82fnhz35";
    "1.20.15" = "sha256:0g4hrdkzrr1vgjvakxg5n9165yiizb0vga996a3qjjh3nim4wdf7";
    "1.21.14" = "sha256:0g3n7q00z89d6li4wilp23z8dxcmdydc3r5g2spmdd82728rav2b";
    "1.22.17" = "sha256:089rnsdk7lc6n3isvnha26nbwjmm1y4glllqnxhj8g9fd3py5jfw";
    "1.23.17" = "sha256:1qcp4miw476rrynp10gkw63aibfrh85qypw40pxfvy0rlahyhcc2";
    # ^ EOL ^
    "1.24.14" = "sha256:1mm3ah08jvp8ghzglf1ljw6qf3ilbil3wzxzs8jzfhljpsxpk41q";
    "1.25.10" = "sha256:0hdv3677yr8a1qs3jb72m7r9ih7xsnd8nhs9fp506lzfl5b7lycc";
    "1.26.5" = "sha256:1dyqvggyvqw3z9sml2x06v1l9kynqcs8bkfrkx8jy81gkvg7qxdi";
    "1.27.2" = "sha256:1yqcds6lvpnvc5dsv9pnvp5qb3kc5y6cdgx827szljdlwf51wd15";
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

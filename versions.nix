let
  full = {
    "1.19.16" = "sha256:15vhl0ibd94rqkq678cf5cl46dxmnanjpq0lmsx15i8l82fnhz35"; # final
    "1.20.15" = "sha256:0g4hrdkzrr1vgjvakxg5n9165yiizb0vga996a3qjjh3nim4wdf7"; # final
    "1.21.14" = "sha256:0g3n7q00z89d6li4wilp23z8dxcmdydc3r5g2spmdd82728rav2b"; # final
    "1.22.12" = "sha256:089rnsdk7lc6n3isvnha26nbwjmm1y4glllqnxhj8g9fd3py5jfw";
    "1.23.9" = "sha256:1wljknhnlw6q8s2rxq8fznjax5z63q5bqci2klm65f46n2vayr9d";
    "1.24.3" = "sha256:0fp5hbqk2q0imrfi4mwp1ia0bmn0xnl6hcr07y52q2cp41pmfhqd";
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

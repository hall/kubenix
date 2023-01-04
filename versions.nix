let
  full = {
    # https://kubernetes.io/releases/patch-releases
    "1.19.16" = "sha256:15vhl0ibd94rqkq678cf5cl46dxmnanjpq0lmsx15i8l82fnhz35"; # final
    "1.20.15" = "sha256:0g4hrdkzrr1vgjvakxg5n9165yiizb0vga996a3qjjh3nim4wdf7"; # final
    "1.21.14" = "sha256:0g3n7q00z89d6li4wilp23z8dxcmdydc3r5g2spmdd82728rav2b"; # final
    "1.22.17" = "sha256:089rnsdk7lc6n3isvnha26nbwjmm1y4glllqnxhj8g9fd3py5jfw"; # final
    "1.23.15" = "sha256:0cw93f46gs1yqwdvfjbbm7kgk85hk6x6f1q9nz8mq352kw4m9zqn";
    "1.24.9" = "sha256:0fp5hbqk2q0imrfi4mwp1ia0bmn0xnl6hcr07y52q2cp41pmfhqd";
    "1.25.5" = "sha256:0811l7j769fa2a329a1kf5lqkaib0bz4c8pbfzg6si0d7614cdcn";
    "1.26.0" = "sha256:0q6xymd642fdpjh8qn8bals0k0v9hcclmm0v1ya30mxlvk0mqk50";
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

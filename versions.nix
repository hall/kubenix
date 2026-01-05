let
  full = {
    # https://kubernetes.io/releases/patch-releases
    "1.19.16" = "sha256:15vhl0ibd94rqkq678cf5cl46dxmnanjpq0lmsx15i8l82fnhz35";
    "1.20.15" = "sha256:0g4hrdkzrr1vgjvakxg5n9165yiizb0vga996a3qjjh3nim4wdf7";
    "1.21.14" = "sha256:0g3n7q00z89d6li4wilp23z8dxcmdydc3r5g2spmdd82728rav2b";
    "1.22.17" = "sha256:089rnsdk7lc6n3isvnha26nbwjmm1y4glllqnxhj8g9fd3py5jfw";
    "1.23.17" = "sha256:1qcp4miw476rrynp10gkw63aibfrh85qypw40pxfvy0rlahyhcc2";
    "1.24.17" = "sha256:1mm3ah08jvp8ghzglf1ljw6qf3ilbil3wzxzs8jzfhljpsxpk41q";
    "1.25.16" = "sha256:0whvanzhf0sv73xarbdskzfc9glh61y17bivm8zi7pigkschlifl";
    "1.26.15" = "sha256:0psn4hxla8m90gw8qk3dw6vvqas7sng6c010xn6bwajl6038bbch";
    "1.27.14" = "sha256:148v1lxp4rmv0pgl41yyz5sjlsk6lr5185nk3qf9nh2gjn1pbw9g";
    "1.28.10" = "sha256:14pvc7ys1x4p6gzmdgabmncl6iwaf2fj0a2j58rv00wndfh62vng";
    "1.29.5" = "sha256:1shik1cbi415cq9ddn564xd1d73g2rzfrna85aqskxavncagkscb";
    "1.30.11" = "sha256:1jy72pkr6pzmgf4d2m40c85ws7pcrv62xnnya0qslv0lgw4j4zqk";
    # ^ EOL ^
    "1.31.9" = "sha256:13bz4jjfix2dnc4bvrcil8np2i5zlz9qfqxmmlgrz1457mf3vjyx";
    "1.32.5" = "sha256:11byhg4hjl22zfvwgn3wxryhgp82ix6v2r310qh5py4xyzkv8d93";
    "1.33.1" = "sha256:1xkykxxhk72n3x01df0jm9pmw24q2rzizwqnwncibbslhpwspx9a";
    "1.34.3" = "sha256:0dqwfpm72x3815l2nrgxw9jdy4kwvicv8nnj0qr7ap51zp1cvc6k";
  };
in
{
  inherit full;
  # sorted list of major.minor version numbers
  # NOTE: avoiding pulling in lib here (not for any good reason)
  versions = with builtins; map
    (v: (
      concatStringsSep "." [
        (elemAt (splitVersion v) 0)
        (elemAt (splitVersion v) 1)
      ]
    ))
    (attrNames full);
}

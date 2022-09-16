{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "vals";
  version = "0.18.0";
  src = fetchFromGitHub {
    owner = "variantdev";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-R0Au34zywb0nv5LOvLb+7wSfn563uzQgiH3mefMlX7A=";
  };

  vendorSha256 = "sha256-fsTUgtMFDPjNJVhBlyq/rWAhOEAOSRQx3l1K0nNK2J8=";
  checkPhase = null;
}

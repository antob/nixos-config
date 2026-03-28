{
  pkgs,
}:
let
  pname = "agent-browser";
  version = "0.23.0";
  repo = pkgs.fetchFromGitHub {
    owner = "vercel-labs";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-ZUcPPsLueMPEiCVXE9N4oBf5xwYvxQ71jfkbo9t/8xs=";
  };
in
pkgs.rustPlatform.buildRustPackage {
  pname = pname;
  version = version;

  buildInputs = with pkgs; [ openssl ];

  nativeBuildInputs = with pkgs; [ pkg-config ];

  src = "${repo}/cli";

  doCheck = false;

  cargoHash = "sha256-Ha+R/tlSYfCb/POuoOauQqYXxmY7Dypn/wp1WwZPQ4w=";
}

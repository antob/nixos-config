{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "rayfish";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "rayfish";
    repo = "rayfish";
    rev = "v${version}";
    sha256 = "sha256-ZCIYrDq/iNWPcfZm+zfr11gDPf3PyvoOJhSOtkbwPOo=";
  };

  cargoHash = "sha256-FjwWUZziqDD1RvVsB6B9FWHHNegKdccaTWf5kS2pZqI=";

  cargoBuildFlags = [
    "--bin"
    "ray"
  ];

  doCheck = false;

  meta = {
    description = "P2P mesh VPN powered by iroh — connect peers by cryptographic identity, not IP address";
    homepage = "https://github.com/rayfish/rayfish";
    license = lib.licenses.mpl20;
    mainProgram = "ray";
    platforms = lib.platforms.linux;
  };
}

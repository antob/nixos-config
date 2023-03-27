{ stdenv, ... }:

stdenv.mkDerivation {
  name = "sfns-display-font";
  version = "2023-03-19";

  src = ./.;

  nativeBuildInputs = [ ];
  buildInputs = [ ];

  buildPhase = "";

  installPhase = ''
    install -m444 -Dt $out/share/fonts/truetype fonts/*.ttf
  '';
}

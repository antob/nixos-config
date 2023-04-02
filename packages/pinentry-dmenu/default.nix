{ pkgs, lib, stdenv, ... }:
let
  pname = "pinentry-dmenu";
in
stdenv.mkDerivation {
  inherit pname;
  version = "2023-04-02";
  src = pkgs.fetchFromGitHub {
    owner = "antob";
    repo = pname;
    rev = "e5ba9ac2b3f7e9d090fbd4162fedc11a4c4bba01";
    sha256 = "sha256-djJgDoooGxr3OTAM/1GPlZSZwWFFoz0p5uokMQb2gIs=";
    name = pname;
  };

  nativeBuildInputs = with pkgs; [
    libassuan
    libconfig
    xorg.libX11
    xorg.libXinerama
    xorg.libXft
    gpgme
  ];

  makeFlags = [ "PREFIX=$(out)" ];
}
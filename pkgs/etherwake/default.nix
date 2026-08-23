{ lib, stdenv }:

stdenv.mkDerivation {
  pname = "etherwake";
  version = "1.09";

  hardeningDisable = [ "format" ];

  src = ./ether-wake.c;
  dontUnpack = true;

  buildPhase = ''
    cc $src -O2 -Wall -o etherwake
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp etherwake $out/bin/
  '';

  meta = with lib; {
    description = "Wake-on-LAN Magic Packet sender";
    homepage = "https://github.com/Fullaxx/etherwake";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    mainProgram = "etherwake";
  };
}

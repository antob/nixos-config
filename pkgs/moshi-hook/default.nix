{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.3.12";
  sources = {
    x86_64-linux = {
      url = "https://cdn.getmoshi.app/hook/v${version}/moshi-hook_Linux_x86_64.tar.gz";
      hash = "sha256-GjuodNFw2TaiDd09ud4PzkenP9l5xUQlT7zKfOkzQks=";
    };
    aarch64-linux = {
      url = "https://cdn.getmoshi.app/hook/v${version}/moshi-hook_Linux_arm64.tar.gz";
      hash = "sha256-qrgw4frYPPY/tdC5FzgIWf9SnmgNFm2+N1ZDADdv/XY=";
    };
  };
in
stdenv.mkDerivation {
  pname = "moshi-hook";
  inherit version;

  src = fetchurl sources.${stdenv.hostPlatform.system};
  sourceRoot = ".";

  installPhase = ''
    install -Dm755 moshi-hook $out/bin/moshi-hook
    ln -s moshi-hook $out/bin/moshi
  '';

  meta = with lib; {
    description = "Portable daemon and CLI that bridges AI coding agents to the Moshi mobile app";
    homepage = "https://getmoshi.app";
    license = licenses.unfree;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "moshi-hook";
  };
}

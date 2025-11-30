{
  lib,
  stdenv,
  fetchgit,
  pkg-config,
  scdoc,
  wayland,
  wayland-scanner,
}:

stdenv.mkDerivation {
  pname = "wlr-dpms";
  version = "251130";

  src = fetchgit {
    url = "https://git.sr.ht/~dsemy/wlr-dpms";
    rev = "b6a4aa82";
    hash = "sha256-NDeLmRQZvWr6Z+aUB9FpEGlDgqoEil2eSwL9yP7V+20=";
  };

  strictDeps = true;
  nativeBuildInputs = [
    pkg-config
    scdoc
    wayland-scanner
  ];
  buildInputs = [ wayland ];
  depsBuildBuild = [
    pkg-config
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp wlr-dpms $out/bin

    mkdir -p $out/share/man/man1
    cp wlr-dpms.1 $out/share/man/man1
  '';

  meta = with lib; {
    description = "wlr-dpms - change output power modes in wlroots compositors";
    homepage = "https://git.sr.ht/~dsemy/wlr-dpms";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "wlr-dpms";
  };
}

{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "gnome-extension-remove-accessibility-menu";
  version = "1";

  src = fetchFromGitHub {
    owner = "antob";
    repo = "gnome-extension-remove-accessibility-menu";
    rev = "1e7559d";
    sha256 = "sha256-K1rplWxbM2paWtk6YicygpXKO1GpNPazmbqhFVaVAmM=";
  };

  passthru = {
    extensionUuid = "remove-accessibility-menu@antob.se";
    extensionPortalSlug = "remove-accessibility-menu";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions
    cp -r "remove-accessibility-menu@antob.se" $out/share/gnome-shell/extensions
    runHook postInstall
  '';

  meta = with lib; {
    description = "This is a GNOME shell extension that removes the accessibility menu.";
  };
}

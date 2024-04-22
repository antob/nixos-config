{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "gnome-extension-expand-shutdown-menu";
  version = "1";

  src = fetchFromGitHub {
    owner = "antob";
    repo = "gnome-extension-expand-shutdown-menu";
    rev = "2feabbe";
    sha256 = "sha256-Kpsoo1J18AmFDLDwTGlYu823RZojpJv7z+0uwzX5hN4=";
  };

  passthru = {
    extensionUuid = "expand-shutdown-menu@antob.se";
    extensionPortalSlug = "expand-shutdown-menu";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions
    cp -r "expand-shutdown-menu@antob.se" $out/share/gnome-shell/extensions
    runHook postInstall
  '';

  meta = with lib; {
    description = "This GNOME shell extension adds a keyboard shortcut to expand the quick settings shutdown menu.";
  };
}

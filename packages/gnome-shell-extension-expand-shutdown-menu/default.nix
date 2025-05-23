{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "gnome-extension-expand-shutdown-menu";
  version = "3";

  src = fetchFromGitHub {
    owner = "antob";
    repo = "gnome-extension-expand-shutdown-menu";
    rev = "6f47101";
    sha256 = "sha256-0nUXZcTsXJkB1+TWxxHYltk5Pui5g+/8WsPH1fYeKo8=";
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

  meta = {
    description = "This GNOME shell extension adds a keyboard shortcut to expand the quick settings shutdown menu.";
  };
}

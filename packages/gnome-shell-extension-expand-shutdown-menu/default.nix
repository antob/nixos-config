{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "gnome-extension-expand-shutdown-menu";
  version = "2";

  src = fetchFromGitHub {
    owner = "antob";
    repo = "gnome-extension-expand-shutdown-menu";
    rev = "c79d373";
    sha256 = "sha256-545tKcN86xmTPMIJeYFt/gJ2AhGqblywBg6NbbG6ewE=";
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

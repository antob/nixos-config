{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "gnome-shell-extension-disable-workspace-switcher";
  version = "1";

  src = fetchFromGitHub {
    owner = "antob"; # Forked for Gnome 46 compability
    repo = "disable-workspace-switcher";
    rev = "0d761d7";
    sha256 = "sha256-YNrHwJGiGOYboSrfXARbWTF2aMZkCA21iS/5kosIRL4=";
  };

  passthru = {
    extensionUuid = "disable-workspace-switcher@jbradaric.me";
    extensionPortalSlug = "disable-workspace-switcher";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions
    cp -r "disable-workspace-switcher@jbradaric.me" $out/share/gnome-shell/extensions
    runHook postInstall
  '';

  meta = {
    description = "GNOME Shell extension that disables the workspace switcher popup.";
  };
}

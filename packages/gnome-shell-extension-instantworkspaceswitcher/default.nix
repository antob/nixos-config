{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "gnome-shell-extension-instantworkspaceswitcher";
  version = "23";

  src = fetchFromGitHub {
    owner = "amalantony";
    repo = "gnome-shell-extension-instant-workspace-switcher";
    rev = "8b0c13d";
    sha256 = "sha256-Ual7kAOeGPe3DF5XHf5eziscYeMLUnDktEGU41Yl4E4=";
  };

  passthru = {
    extensionUuid = "instantworkspaceswitcher@amalantony.net";
    extensionPortalSlug = "instantworkspaceswitcher";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions
    cp -r "instantworkspaceswitcher@amalantony.net" $out/share/gnome-shell/extensions
    runHook postInstall
  '';

  meta = with lib; {
    description = "This GNOME shell extension disables the workspace switching animation.";
  };
}

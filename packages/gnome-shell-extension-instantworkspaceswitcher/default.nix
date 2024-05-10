{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "gnome-shell-extension-instantworkspaceswitcher";
  version = "23";

  src = fetchFromGitHub {
    # owner = "amalantony";
    owner = "Dritzii"; # Forked for Gnome 46 compability.
    repo = "gnome-shell-extension-instant-workspace-switcher";
    rev = "171e310";
    sha256 = "sha256-7nPpUz19ydHhrahMghxI0q+BJtGd7Ro+zQsBdN4bWyE=";
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

  meta = {
    description = "This GNOME shell extension disables the workspace switching animation.";
  };
}

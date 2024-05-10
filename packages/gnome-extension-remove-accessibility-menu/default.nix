{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "gnome-extension-remove-accessibility-menu";
  version = "2";

  src = fetchFromGitHub {
    owner = "antob";
    repo = "gnome-extension-remove-accessibility-menu";
    rev = "8d50b0c";
    sha256 = "sha256-va5fFbrg6q3Y7ogzunYaUBcmXPnMsaXUH+RFm70iC4c=";
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

  meta = {
    description = "This is a GNOME shell extension that removes the accessibility menu.";
  };
}

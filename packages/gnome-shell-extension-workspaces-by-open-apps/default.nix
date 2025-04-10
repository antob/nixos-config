{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "gnome-extension-workspaces-by-open-apps";
  version = "20";

  src = fetchFromGitHub {
    owner = "antob";
    repo = "workspaces-by-open-apps";
    rev = "a88912b";
    sha256 = "sha256-SppTtTjKPF+h7qzLDJKKLQSlmP0BhnJnEo8bIoeoDiw=";
  };

  passthru = {
    extensionUuid = "workspaces-by-open-apps@favo02.github.com";
    extensionPortalSlug = "workspaces-by-open-apps";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions
    cp -r src $out/share/gnome-shell/extensions/workspaces-by-open-apps@favo02.github.com
    runHook postInstall
  '';

  meta = {
    description = "GNOME shell estension to display a simple workspace indicator showing icons of apps open in it instead of classic numbers or dots.";
  };
}

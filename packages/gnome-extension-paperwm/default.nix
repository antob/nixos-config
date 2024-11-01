{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "gnome-extension-paperwm";
  version = "v47.1.0";

  src = fetchFromGitHub {
    owner = "paperwm";
    repo = "PaperWM";
    rev = version;
    sha256 = "sha256-9cREe41cACf8/Ab1g0gwUdS7XJ1zFfczv0FtNFSb+W0=";
  };

  passthru = {
    extensionUuid = "paperwm@paperwm.github.com";
    extensionPortalSlug = "PaperWM";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions/paperwm@paperwm.github.com
    cp -r . $out/share/gnome-shell/extensions/paperwm@paperwm.github.com
    runHook postInstall
  '';

  meta = {
    description = "PaperWM is a Gnome Shell extension which provides scrollable tiling of windows and per monitor workspaces.";
  };
}

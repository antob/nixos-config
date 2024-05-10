{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "gnome-shell-extension-switcher";
  version = "23";

  src = fetchFromGitHub {
    owner = "daniellandau";
    repo = "switcher";
    rev = "2e6b145";
    sha256 = "sha256-tZVFg3mo/CAel+AJzUl+ExfgDkHR6hS2765woYAi6y4=";
  };

  passthru = {
    extensionUuid = "switcher@landau.fi";
    extensionPortalSlug = "switcher";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions/switcher@landau.fi
    cp -r $src/* $out/share/gnome-shell/extensions/switcher@landau.fi
    runHook postInstall
  '';

  meta = {
    description = "Switcher is a Gnome Shell extension for quickly switching windows by typing.";
  };
}

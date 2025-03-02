{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "zsh-window-title";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "olets";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-RqJmb+XYK35o+FjUyqGZHD6r1Ku1lmckX41aXtVIUJQ=";
  };

  strictDeps = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/share/${pname}
    cp *.zsh $out/share/${pname}/
  '';

  meta = with lib; {
    homepage = "https://github.com/olets/zsh-window-title";
    license = licenses.cc-by-nc-sa-40;
    description = "A zsh plugin for informative terminal window titles";
  };
}

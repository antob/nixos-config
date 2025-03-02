{
  pkgs,
  stdenv,
  fetchFromGitHub,
}:
let
  pname = "vscode-extension-vs64";
  version = "2.5.19";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "antob";
    repo = "vs64";
    rev = "25ab67b";
    sha256 = "sha256-W253LCtAQgHKsf6JgOKEaj/Upztt0YBwd/7O8/nIQ6U=";
  };

  buildInputs = with pkgs; [
    nodejs
    unzip
  ];

  buildPhase = "";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/vscode/extensions/antob.vs64
    unzip -d $out/share/vscode/extensions/antob.vs64 vs64-${version}.vsix
    runHook postInstall
  '';

  meta = {
    description = "VS64 - The C64 Development Environment";
  };
}

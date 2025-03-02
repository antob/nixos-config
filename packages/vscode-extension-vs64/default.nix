{
  pkgs,
  stdenv,
  fetchFromGitHub,
}:
let
  pname = "vscode-extension-vs64";
  version = "2.5.19";
  vscodeExtPublisher = "antob";
  vscodeExtName = "vs64";
  vscodeExtUniqueId = "antob.vs64";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = vscodeExtPublisher;
    repo = vscodeExtName;
    rev = "25ab67b";
    sha256 = "sha256-29RTnQ/NebFJ/fAQAQJDM/eMC56G/x+l53Gpp4frtFk=";
  };

  passthru = {
    inherit vscodeExtPublisher vscodeExtName vscodeExtUniqueId;
  };

  buildInputs = with pkgs; [
    nodejs
    unzip
  ];

  buildPhase = "";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/vscode/extensions
    unzip vs64-${version}.vsix
    mv extension $out/share/vscode/extensions/${vscodeExtUniqueId}
    runHook postInstall
  '';

  meta = {
    description = "VS64 - The C64 Development Environment";
  };
}

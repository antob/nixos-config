{
  lib,
  pkgs,
  fetchFromGitHub,
  fetchNpmDeps,
  npmHooks,
  runtimeShell,
}:
pkgs.stdenv.mkDerivation rec {
  pname = "m68k-lsp-server";
  version = "0.11.2";

  src = fetchFromGitHub {
    owner = "grahambates";
    repo = "m68k-lsp";
    rev = "v${version}";
    sha256 = "sha256-Ac8qbx5FGC4vVkmhPe+zjS5ZM7JwRdeUIj3cMBfKAzE=";
  };

  env.rootNpmDeps = fetchNpmDeps {
    name = "root-npm-deps";
    inherit src;
    hash = "sha256-heU3h+60OEfUvjg6Ypk3VEC3vEpauXnqjGBeixX/25Y=";
  };
  env.clientNpmDeps = fetchNpmDeps {
    name = "client-npm-deps";
    src = "${src}/client";
    hash = "sha256-R3CgYZsvl8qEW/XkTJi8A/aZWje74ma1/4D+/AB7Ld8=";
  };
  env.serverNpmDeps = fetchNpmDeps {
    name = "server-npm-deps";
    src = "${src}/server";
    hash = "sha256-HOIeY/iPSavdIgq8Nn0F4WTsFjdxihLCC9FagrQdRlo=";
  };

  npmFlags = [
    "--ignore-scripts"
  ];

  nativeBuildInputs = with pkgs; [
    nodejs
  ];

  postPatch = ''
    # Tricky way to run npmConfigHook multiple times
    local postPatchHooks=() # written to by npmConfigHook
    source ${npmHooks.npmConfigHook}/nix-support/setup-hook
    npmRoot=. npmDeps=$rootNpmDeps npmConfigHook
    npmRoot=client npmDeps=$clientNpmDeps npmConfigHook
    npmRoot=server npmDeps=$serverNpmDeps npmConfigHook
  '';

  buildPhase = ''
    npm run build
  '';

  binWrapper = ''
    #!${runtimeShell}
    ${pkgs.nodejs}/bin/node ${placeholder "out"}/lib/server.js "$@"
  '';

  passAsFile = [ "binWrapper" ];

  installPhase = ''
    mkdir -p $out/lib
    cp -r server/node_modules $out/lib/
    cp server/out/server.js $out/lib/

    mkdir -p $out/bin
    cp $binWrapperPath $out/bin/m68k-lsp-server
    chmod +x $out/bin/m68k-lsp-server

    cp -r server/wasm $out/
  '';

  meta = with lib; {
    description = "Motorola 68000 family language server";
    homepage = "https://github.com/grahambates/m68k-lsp";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "m68k-lsp-server";
  };
}

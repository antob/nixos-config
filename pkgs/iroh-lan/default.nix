{
  lib,
  stdenv,
  cargo-tauri,
  glib-networking,
  libayatana-appindicator,
  libsoup_3,
  nodejs,
  openssl,
  pkg-config,
  fetchFromGitHub,
  pnpm_10,
  fetchPnpmDeps,
  pnpmConfigHook,
  rustPlatform,
  webkitgtk_4_1,
  wrapGAppsHook4,
}:

rustPlatform.buildRustPackage (finalAttrs: rec {
  pname = "iroh-lan-ui";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "rustonbsd";
    repo = "iroh-lan";
    rev = "v${version}";
    sha256 = "sha256-eD14PBfSh8cNOOrPdQlx8F9e5jwD+Z9R2l5gvyYJEx8=";
  };

  postPatch = ''
    substituteInPlace $cargoRoot/Cargo.toml \
      --replace-fail 'path = "../../../iroh-lan"' 'path = "../.."'
    substituteInPlace $cargoDepsCopy/*/libappindicator-sys-*/src/lib.rs \
      --replace-fail "libayatana-appindicator3.so.1" "${libayatana-appindicator}/lib/libayatana-appindicator3.so.1"
  '';

  # Rust dependencies of the Tauri crate (ui/src-tauri/Cargo.lock).
  cargoRoot = "ui/src-tauri";
  buildAndTestSubdir = "ui/src-tauri";
  cargoHash = "sha256-xoAjnr7RPB1qkSvbEIQGkAT6C5B5g+TyApmqFzuz3rc=";

  # Frontend (React/Vite) dependencies, fetched from ui/pnpm-lock.yaml.
  pnpmRoot = "ui";
  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs)
      pname
      version
      src
      ;
    pnpm = pnpm_10;
    fetcherVersion = 4;
    postPatch = "cd ${finalAttrs.pnpmRoot}";
    hash = "sha256-R1vH/eTb3UHgiw22vQOhtOKsE3zCWsi90FOwfmPuORc=";
  };

  nativeBuildInputs = [
    cargo-tauri.hook
    nodejs
    pnpmConfigHook
    pnpm_10
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    openssl
    glib-networking
    libayatana-appindicator
    libsoup_3
    webkitgtk_4_1
  ];

  env.OPENSSL_NO_VENDOR = 1;

  # Force the native Wayland backend via the gapps wrapper.
  # An explicit GDK_BACKEND in the environment still wins;
  # X11-only users should set GDK_BACKEND=x11.
  preFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    gappsWrapperArgs+=(--set-default GDK_BACKEND wayland)
  '';

  meta = with lib; {
    description = "iroh-lan = hamachi - account - install";
    homepage = "https://github.com/rustonbsd/iroh-lan";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "iroh-lan-ui";
  };
})

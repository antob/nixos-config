{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.antob.cli-apps.neovim;

  user = config.antob.user.name;
  inherit (config.antob.user) group;
  userHome = "/home/${user}";

  # Inspired from https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/programs/nix-ld.nix
  build-dependent-pkgs = with pkgs; [
    acl
    attr
    bzip2
    curl
    libsodium
    libssh
    libxml2
    openssl
    stdenv.cc.cc
    systemd
    util-linux
    xz
    zlib
    zstd
    # Packages not included in `nix-ld`'s NixOSModule
    glib
    libcxx
  ];

  makePkgConfigPath = x: makeSearchPathOutput "dev" "lib/pkgconfig" x;
  makeIncludePath = x: makeSearchPathOutput "dev" "include" x;

  # dlopen()/ffi.load() and `-lfoo` linking look libraries up by their
  # unversioned name (`libfoo.so`), but most nixpkgs packages only ship
  # versioned files (`libfoo.so.<n>`). Create the missing unversioned
  # symlinks so lookups succeed (e.g. notmuch.nvim doing
  # `ffi.load("notmuch")` -> `libnotmuch.so`).
  addUnversionedSoSymlinks = ''
    cd "$out/lib/nvim-depends/lib"
    for libfile in *; do
      case "$libfile" in
        *.so | *.so.*) ;;
        *) continue ;;
      esac
      case "$libfile" in
        *.so) continue ;;
      esac
      # only numeric version suffixes (libfoo.so.1, libfoo.so.1.2.3)
      version="''${libfile##*.so.}"
      case "$version" in
        *[!0-9.]* | "") continue ;;
      esac
      unversioned="''${libfile%%.so.*}.so"
      [ -e "$unversioned" ] || ln -s "$libfile" "$unversioned"
    done
  '';

  nvim-depends-library = pkgs.buildEnv {
    name = "nvim-depends-library";
    paths = map lib.getLib build-dependent-pkgs;
    extraPrefix = "/lib/nvim-depends";
    pathsToLink = [ "/lib" ];
    ignoreCollisions = true;
    postBuild = addUnversionedSoSymlinks;
  };
  nvim-depends-include = pkgs.buildEnv {
    name = "nvim-depends-include";
    paths = splitString ":" (makeIncludePath build-dependent-pkgs);
    extraPrefix = "/lib/nvim-depends/include";
    ignoreCollisions = true;
  };
  nvim-depends-pkgconfig = pkgs.buildEnv {
    name = "nvim-depends-pkgconfig";
    paths = splitString ":" (makePkgConfigPath build-dependent-pkgs);
    extraPrefix = "/lib/nvim-depends/pkgconfig";
    ignoreCollisions = true;
  };

  # Runtime dlopen()/ffi.load() search path. Deliberately NOT the full
  # `build-dependent-pkgs` set: `LD_LIBRARY_PATH` is inherited by every
  # child process nvim spawns (`:terminal`, LSP servers, jobstart, direnv
  # shells, ...), and exposing toolchain libraries there (e.g.
  # `libstdc++.so.6`/`libgcc_s.so.1` from `stdenv.cc.cc`) breaks children
  # built against other nixpkgs generations (older direnv devshells, etc.).
  # Only packages explicitly listed in `extraDependentPackages` are exposed
  # at runtime; the rest stay in build-time-only variables below.
  nvim-depends-runtime = pkgs.buildEnv {
    name = "nvim-depends-runtime";
    paths = map lib.getLib [ ]; # cfg.extraDependentPackages;
    extraPrefix = "/lib/nvim-depends";
    pathsToLink = [ "/lib" ];
    ignoreCollisions = true;
    postBuild = addUnversionedSoSymlinks;
  };

  # Env vars are injected into the nvim *wrapper* (makeWrapper args) instead
  # of a shell alias: an alias only applies to `nvim` typed in an
  # interactive shell and is bypassed by the `nv`/`nvl`/`lc` zsh functions
  # (they exec "$@", which never expands aliases), neovide, $EDITOR calls,
  # desktop entries, etc. Wrapping the binary makes `extraDependentPackages`
  # work for runtime dlopen()/ffi.load() regardless of how nvim is launched.
  #
  # CPATH/CPLUS_INCLUDE_PATH/LIBRARY_PATH/PKG_CONFIG_PATH/NIX_LD_LIBRARY_PATH
  # are build-time only (consumed by gcc/ld/pkg-config/nix-ld, ignored by the
  # runtime dynamic linker), so they can safely carry the full dependency set.
  # LD_LIBRARY_PATH is the only one ld.so consults at runtime, so it is
  # restricted to `nvim-depends-runtime` (see above).
  wrapperEnvArgs = [
    "--suffix"
    "CPATH"
    ":"
    "${nvim-depends-include}/lib/nvim-depends/include"
    "--suffix"
    "CPLUS_INCLUDE_PATH"
    ":"
    "${nvim-depends-include}/lib/nvim-depends/include/c++/v1"
    "--suffix"
    "LIBRARY_PATH"
    ":"
    "${nvim-depends-library}/lib/nvim-depends/lib"
    "--suffix"
    "NIX_LD_LIBRARY_PATH"
    ":"
    "${nvim-depends-library}/lib/nvim-depends/lib"
    "--suffix"
    "PKG_CONFIG_PATH"
    ":"
    "${nvim-depends-pkgconfig}/lib/nvim-depends/pkgconfig"
    "--suffix"
    "LD_LIBRARY_PATH"
    ":"
    "${nvim-depends-runtime}/lib/nvim-depends/lib"
    "--set-default"
    "SQLITE_CLIB_PATH"
    "${pkgs.sqlite.out}/lib/libsqlite3.so"
  ];
in
{
  options.antob.cli-apps.neovim = with types; {
    enable = mkEnableOption "Whether or not to enable neovim";
    minimal = mkBoolOpt false "Whether or not to only do minimal install.";
    localConfig = mkBoolOpt false "Whether or not to use a local or generated config.";
  };

  imports = [
    ./plugins
  ];

  config = mkIf cfg.enable (mkMerge [
    (mkIf (!cfg.localConfig) {
      antob.home.extraOptions = {
        imports = [
          ./options.nix
          ./utils.nix
          ./colorscheme.nix
          ./autocmd.nix
          ./filetypes.nix
          ./keymaps.nix
        ]
        ++ lib.optionals (!cfg.minimal) [
          ./syntax
          ./diagnostic.nix
          ./lsp
        ];
        programs.neovim = {
          enable = true;
          vimAlias = true;
          withRuby = !cfg.minimal;
          withPython3 = !cfg.minimal;
        };
      };
    })
    (mkIf cfg.localConfig {
      environment.systemPackages = with pkgs; [
        marksman # required by nvim-lspconfig
        neovim-remote # required by lazygit
        tree-sitter # required by nvim-treesitter

        # required by nvim
        fswatch

        # required by telescope.nvim
        fd
        ripgrep
      ];

      # populates contents of /bin and /usr/bin/
      services.envfs.enable = lib.mkDefault true;

      # more info: https://github.com/mcdonc/.nixconfig/blob/master/videos/pydev/script.rst
      # run unpatched dynamic binaries on NixOS
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          # nix-ld adds the following libs by default
          zlib
          zstd
          stdenv.cc.cc
          curl
          openssl
          attr
          libssh
          bzip2
          libxml2
          acl
          libsodium
          util-linux
          xz
          systemd

          # custom libs
          stdenv.cc.cc.lib
          fontconfig
          freetype
        ];
      };

      antob.home.extraOptions = {
        home.packages = with pkgs; [
          ripgrep
          nvim-depends-include
          nvim-depends-library
          nvim-depends-pkgconfig
          patchelf
        ];

        home.extraOutputsToInstall = [ "nvim-depends" ];

        programs.neovim = {
          enable = true;
          package = pkgs.neovim-unwrapped;

          initLua = "";
          sideloadInitLua = true;

          vimAlias = true;
          withNodeJs = false;
          withPython3 = false;
          withRuby = false;

          extraWrapperArgs = wrapperEnvArgs;

          extraPackages = with pkgs; [
            # Dependent packages used by default plugins
            doq
            sqlite
            cargo
            clang
            cmake
            gcc
            gnumake
            ninja
            pkg-config
            yarn
            luarocks
            go
            # stylua
            # rubocop
            # ruby-lsp
            ruby
            bundler
            rubocop
          ];

          # NOTE: extraLuaPackages doesn't work?
          # https://github.com/NixOS/nixpkgs/issues/306367
          # https://github.com/NixOS/nixpkgs/pull/301573
          extraLuaPackages =
            ls: with ls; [
              luarocks
              # required by 3rd/image.nvim
              magick
            ];
        };
      };

      fileSystems."${userHome}/.config/nvim" = {
        device = "${userHome}/Projects/nvim-config";
        options = [ "bind" ];
        fsType = "none";
      };

      systemd.tmpfiles.rules = [
        "d ${userHome}/.config/nvim 0755 ${user} ${group} -"
      ];
    })
  ]);
}

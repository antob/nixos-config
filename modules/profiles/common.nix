{ config, ... }:
let
  inherit (config.aspects) homeManager nixos;
in
{
  flake.modules.nixos.common =
    { pkgs, ... }:
    {
      imports = with nixos; [
        server
        direnv
        devenv
        rustup
        fhs
        fonts
        audio
        scripts
        alacritty
        nix-search-tv
      ];

      config = {
        home-manager.sharedModules = [ homeManager.common ];

        antob.neovim.minimal = false;

        environment = {
          shellAliases = {
            http = "xh";
            https = "xhs";
            j = "just";
            open = "xdg-open";
            hexyl = "hexyl --border none --color-scheme gradient";
          };

          systemPackages = with pkgs; [
            fwupd
            doggo
            jqp
            xh
            fastfetch
            cifs-utils # Mount SMB shares
            nix-search-tv
            just
            nixos-anywhere
            man-pages
            man-pages-posix
            wl-color-picker
            masscan
            whatweb
            difftastic
            ffmpeg
            imagemagick
            hexyl
            ssh-to-pgp
          ];
        };

        services = {
          fwupd.enable = true;
          # Disable for now to avoid failed systemd
          # units (`bin.mount` and `usr-bin.mount`) on startup
          # envfs.enable = true;
        };

        hardware.graphics.enable = true;

        documentation = {
          enable = true;
          man.enable = true;
          man.man-db.enable = true;
          dev.enable = true;
        };
      };
    };

  flake.modules.homeManager.common = {
    programs = {
      password-store = {
        enable = true;
        settings = {
          PASSWORD_STORE_DIR = "$XDG_DATA_HOME/password-store";
        };
      };

      # DNS lookup failure on update during boot
      # tealdeer.enable = true;
    };
  };
}

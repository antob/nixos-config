{ config, ... }:
let
  inherit (config.aspects) homeManager nixos;
in
{
  flake.modules.nixos.desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    {
      imports = [
        nixos.bluetooth
        nixos.ledger
        nixos.webcam
        nixos.yubikey
        nixos.zsa-voyager
        nixos.printing
        nixos.syncthing
        nixos.virt-manager
        nixos.vscode
        nixos.firefox
        nixos.udisks2
      ];

      config = {
        home-manager.sharedModules = [ homeManager.desktop ];

        services = {
          gvfs.enable = true;
          chrony.enable = true;

          # NFS shares
          rpcbind.enable = true;
        };

        systemd = {
          # NFS shares
          mounts = [
            {
              type = "nfs4";
              mountConfig = {
                Options = "noatime";
              };
              what = "10.64.1.2:/mnt/tank/share/public";
              where = "/mnt/share/public";
            }
            {
              type = "nfs4";
              mountConfig = {
                Options = "noatime";
              };
              what = "10.64.1.2:/mnt/tank/share/private";
              where = "/mnt/share/private";
            }
          ];

          automounts = [
            {
              wantedBy = [ "multi-user.target" ];
              automountConfig = {
                TimeoutIdleSec = "600";
              };
              where = "/mnt/share/public";
            }
            {
              wantedBy = [ "multi-user.target" ];
              automountConfig = {
                TimeoutIdleSec = "600";
              };
              where = "/mnt/share/private";
            }
          ];
        };

        environment.systemPackages = with pkgs; [
          arandr
          ungoogled-chromium
          libreoffice-stable
          gimp
          mpv
          imv
          vlc
          gnome-calculator
          evince
          # remmina # Remote Desktop Client
          # TODO: renderer crashes (webFrame defineProperty) on electron 43.8.3; revert once fixed
          prev.obsidian
          discord
          mqtt-explorer
          rustdesk-flutter
          vulkan-tools
          acpi
          quickemu
          nfs-utils # Needed for mounting NFS shares
        ];

        antob.persistence = {
          directories = [
            {
              directory = "/var/lib/chrony";
              user = "chrony";
              group = "chrony";
              mode = "0750";
            }
          ];

          home.directories = [
            ".config/discord"
            ".config/irb"
            ".config/obsidian"
            ".config/chromium"
            ".config/MQTT-Explorer"
            ".config/rustdesk"
          ];
        };

        # Enable DHCP on the wireless link
        networking.useDHCP = lib.mkDefault true;
      };
    };

  flake.modules.homeManager.desktop =
    { lib, ... }:
    {
      # Default apps
      xdg.mimeApps.defaultApplications = {
        # Open all images with imv
        "image/png" = [ "imv.desktop" ];
        "image/jpeg" = [ "imv.desktop" ];
        "image/gif" = [ "imv.desktop" ];
        "image/webp" = [ "imv.desktop" ];
        "image/bmp" = [ "imv.desktop" ];
        "image/tiff" = [ "imv.desktop" ];

        # Open PDFs with the Document Viewer
        "application/pdf" = [ "org.gnome.Evince.desktop" ];

        # Open video files with mpv
        "video/mp4" = [ "mpv.desktop" ];
        "video/x-msvideo" = [ "mpv.desktop" ];
        "video/x-matroska" = [ "mpv.desktop" ];
        "video/x-flv" = [ "mpv.desktop" ];
        "video/x-ms-wmv" = [ "mpv.desktop" ];
        "video/mpeg" = [ "mpv.desktop" ];
        "video/ogg" = [ "mpv.desktop" ];
        "video/webm" = [ "mpv.desktop" ];
        "video/quicktime" = [ "mpv.desktop" ];
        "video/3gpp" = [ "mpv.desktop" ];
        "video/3gpp2" = [ "mpv.desktop" ];
        "video/x-ms-asf" = [ "mpv.desktop" ];
        "video/x-ogm+ogg" = [ "mpv.desktop" ];
        "video/x-theora+ogg" = [ "mpv.desktop" ];
        "application/ogg" = [ "mpv.desktop" ];
      };
    };

}

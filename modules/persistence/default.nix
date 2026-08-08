{
  config,
  lib,
  inputs,
  ...
}:

with lib;
let
  cfg = config.antob.persistence;
  userName = config.antob.user.name;
in
{
  imports = [ inputs.preservation.nixosModules.preservation ];

  options.antob.persistence = with types; {
    enable = mkEnableOption "Enable persistence storage.";
    path = mkOpt str "/persist" "Path to persistent folder.";
    files = mkOpt (listOf anything) [ ] "A list of files to be stored in persistent storage.";
    directories =
      mkOpt (listOf anything) [ ]
        "A list of directories to be stored in persistent storage.";
    home = {
      files =
        mkOpt (listOf anything) [ ]
          "A list of files in user home to be stored in persistant storage.";
      directories =
        mkOpt (listOf anything) [ ]
          "A list of directories in user home to be stored in persistant storage.";
    };
    safe = {
      files =
        mkOpt (listOf anything) [ ]
          "A list of files to be stored in persistent storage and backed up offsite.";
      directories =
        mkOpt (listOf anything) [ ]
          "A list of directories to be stored in persistent storage and backed up offsite.";
      home = {
        files =
          mkOpt (listOf anything) [ ]
            "A list of files in user home to be stored in persistant storage and backed up offsite.";
        directories =
          mkOpt (listOf anything) [ ]
            "A list of directories in user home to be stored in persistant storage and backed up offsite.";
      };
    };
  };

  config = mkIf cfg.enable {
    preservation = {
      enable = true;
      preserveAt = {
        "${cfg.path}" = {
          commonMountOptions = [
            "x-gvfs-hide"
            "x-gdu.hide"
          ];
          files = cfg.files;
          directories = cfg.directories ++ [
            "/var/log"
            "/var/cache"
            {
              directory = "/var/lib/nixos";
              inInitrd = true;
            }
            "/var/lib/boltd"
            "/var/lib/logrotate"
            "/var/lib/fwupd"
            "/var/lib/libvirt"
            {
              directory = "/var/lib/systemd";
              inInitrd = true;
            }
          ];
          users."${userName}" = {
            inherit (cfg.home) files directories;
          };
        };

        "${cfg.path}/safe" = {
          commonMountOptions = [
            "x-gvfs-hide"
            "x-gdu.hide"
          ];
          files = cfg.safe.files ++ [
            {
              file = "/etc/machine-id";
              inInitrd = true;
            }
            {
              file = "/etc/ssh/ssh_host_rsa_key";
              how = "symlink";
              inInitrd = true;
              configureParent = true;
            }
            {
              file = "/etc/ssh/ssh_host_ed25519_key";
              how = "symlink";
              inInitrd = true;
              configureParent = true;
            }
          ];
          directories = cfg.safe.directories;
          users."${userName}" = {
            inherit (cfg.safe.home) files directories;
          };
        };
      };
    };

    systemd.tmpfiles.settings.preservation = {
      "/home/${userName}/.config".d = {
        user = userName;
        group = "users";
        mode = "0755";
      };
      "/home/${userName}/.local".d = {
        user = userName;
        group = "users";
        mode = "0755";
      };
      "/home/${userName}/.local/share".d = {
        user = userName;
        group = "users";
        mode = "0755";
      };
      "/home/${userName}/.local/state".d = {
        user = userName;
        group = "users";
        mode = "0755";
      };
    };
    # systemd-machine-id-commit.service would fail, but it is not relevant
    # in this specific setup for a persistent machine-id so we disable it
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

    # Make logrotate use a persistent state file.
    services.logrotate.extraArgs = lib.mkAfter [
      "--state"
      "/var/lib/logrotate/logrotate.status"
    ];
  };
}

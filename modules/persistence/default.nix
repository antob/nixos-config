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
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.antob.persistence = with types; {
    enable = mkEnableOption "Enable persistence using impermanence.";
    files = mkOpt (listOf (
      either str attrs
    )) [ ] "A list of files to be managed by impermanence's <option>files</option>.";
    directories = mkOpt (listOf (
      either str attrs
    )) [ ] "A list of directories to be managed by impermanence's <option>directories</option>.";
    home = {
      files = mkOpt (listOf (
        either str attrs
      )) [ ] "A list of files to be managed by impermanence's home-manager <option>files</option>.";
      directories =
        mkOpt (listOf (either str attrs)) [ ]
          "A list of directories to be managed by impermanence's home-manager <option>directories</option>.";
    };
    safe = {
      files = mkOpt (listOf (
        either str attrs
      )) [ ] "A list of backed up files to be managed by impermanence's <option>files</option>.";
      directories =
        mkOpt (listOf (either str attrs)) [ ]
          "A list of backed up directories to be managed by impermanence's <option>directories</option>.";
      home = {
        files =
          mkOpt (listOf (either str attrs)) [ ]
            "A list of backed up files to be managed by impermanence's home-manager <option>files</option>.";
        directories =
          mkOpt (listOf (either str attrs)) [ ]
            "A list of backed up directories to be managed by impermanence's home-manager <option>directories</option>.";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /nix/persist/safe 0755 root root -"
      "d /nix/persist/var/log 0755 root root -"
      "d /nix/persist/var/lib/nixos 0755 root root -"
      "d /nix/persist/var/lib/systemd/coredump 0755 root root -"
    ];

    # Necessary for user-specific impermanence
    # programs.fuse.userAllowOther = true;

    environment.persistence."/nix/persist" = {
      hideMounts = true;
      directories = cfg.directories ++ [
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/lib/systemd/backlight"
      ];
      files = cfg.files ++ [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
      ];
      users."${userName}" = {
        inherit (cfg.home) files directories;
      };
    };

    environment.persistence."/nix/persist/safe" = {
      hideMounts = true;
      inherit (cfg.safe) files directories;
      users."${userName}" = {
        inherit (cfg.safe.home) files directories;
      };
    };
  };
}

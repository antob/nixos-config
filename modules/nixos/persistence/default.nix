{
  config,
  lib,
  inputs,
  ...
}:

with lib;
let
  cfg = config.antob.persistence;
  user = config.users.users.${config.antob.user.name};

in
{
  imports = with inputs; [ impermanence.nixosModules.impermanence ];

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
      "d /persist/safe 0755 root root -"
      "d /persist/safe/home 0755 ${user.name} ${user.group} -"
      "d /persist/home 0755 ${user.name} ${user.group} -"
    ];

    # Necessary for user-specific impermanence
    programs.fuse.userAllowOther = true;

    environment.persistence."/persist" = {
      hideMounts = true;
      inherit (cfg) files directories;
    };

    environment.persistence."/persist/safe" = {
      hideMounts = true;
      inherit (cfg.safe) files directories;
    };

    antob.home.extraOptions = {
      imports = [ inputs.impermanence.nixosModules.home-manager.impermanence ];

      home.persistence."/persist/home/${config.antob.user.name}" = {
        inherit (cfg.home) files directories;
        allowOther = true;
      };

      home.persistence."/persist/safe/home/${config.antob.user.name}" = {
        inherit (cfg.safe.home) files directories;
        allowOther = true;
      };
    };
  };
}

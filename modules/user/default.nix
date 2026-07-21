{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.user;

  defaultIconFileName = "profile.png";
  defaultIcon = pkgs.stdenvNoCC.mkDerivation {
    name = "default-icon";
    src = ./. + "/${defaultIconFileName}";

    dontUnpack = true;

    installPhase = ''
      cp $src $out
    '';

    passthru = {
      fileName = defaultIconFileName;
    };
  };
  propagatedIcon =
    pkgs.runCommand "propagated-icon"
      {
        passthru = {
          fileName = cfg.icon.fileName;
        };
      }
      ''
        local target="$out/share/antob-icons/user/${cfg.name}"
        mkdir -p "$target"

        cp ${cfg.icon} "$target/${cfg.icon.fileName}"
      '';
in
{
  options.antob.user = with types; {
    name = mkOpt str "tob" "The name to use for the user account.";
    group = mkOpt str "users" "The group to use for the user account.";
    fullName = mkOpt str "Tobias Lindholm" "The full name of the user.";
    email = mkOpt str "tobias.lindholm@antob.se" "The email of the user.";
    shortEmail = mkOpt str "tob@antob.se" "The short email of the user.";
    icon = mkOpt (nullOr package) defaultIcon "The profile picture to use for the user.";
    hashedPassword =
      mkOpt str
        "$6$fiUqUwx2M4O9FLP7$K3x8sAjSmpjyn6Rjjk/abv3QgONKU.sQ/QUWtcafiZ6WNXE/UzVv6QeOEwCXkBHy5iJV6tg2ai0p2ApA/rABs0"
        "Hash of the user password `changeme`. To generate a hashed password run `mkpasswd -m sha-512`.";
    autoLogin = mkBoolOpt true "Whether or not to autologin user.";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
    extraOptions = mkOpt attrs { } "Extra options passed to <option>users.users.<name></option>.";
  };

  config = {
    antob = {
      home.file = {
        ".face".source = cfg.icon;
        "Pictures/${cfg.icon.fileName or (builtins.baseNameOf cfg.icon)}".source = cfg.icon;
      };

      persistence.home.directories = [
        ".cache"
        ".local/share/Trash"
        ".local/share/zoxide"
        "Downloads"
        ".local/share/password-store"
        "Projects"
        "Documents"
        "Pictures"
        "Videos"
        "Music"
        "persist"
      ];
    };

    environment.systemPackages = [ propagatedIcon ];

    # Enable passwordless sudo for wheel group
    security.sudo.wheelNeedsPassword = false;

    users = {
      mutableUsers = false;
      users.${cfg.name} = {
        isNormalUser = true;

        inherit (cfg) name hashedPassword;

        home = "/home/${cfg.name}";
        group = cfg.group;

        shell = mkIf config.antob.tools.zsh.enable pkgs.zsh;

        extraGroups = [
          "wheel"
          "dialout"
        ]
        ++ cfg.extraGroups;
      }
      // cfg.extraOptions;
    };
  };
}

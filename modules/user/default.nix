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
    pkgs.runCommandNoCC "propagated-icon"
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
    icon = mkOpt (nullOr package) defaultIcon "The profile picture to use for the user.";
    hashedPassword =
      mkOpt str "$y$j9T$wjUKjUTgvrxCg7HVJIrl2/$A0nvjyLzv869pQYmjyuIgXafrZDk2Lzg9B/nA/W4609"
        "Hash of the user password password. To generate a hashed password run `mkpasswd`.";
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

      persistence = {
        home = {
          directories = [
            ".cache"
            ".local/share/zoxide"
            "Downloads"
            "persist"
          ];
          files = [ ".fehbg" ];
        };

        safe.home = {
          directories = [
            ".local/share/password-store"
            "Projects"
            "Documents"
            "Pictures"
            "Videos"
            "Music"
          ];
        };
      };
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

        extraGroups = [ "wheel" ] ++ cfg.extraGroups;
      } // cfg.extraOptions;
    };
  };
}

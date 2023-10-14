{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
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

    passthru = { fileName = defaultIconFileName; };
  };
  propagatedIcon = pkgs.runCommandNoCC "propagated-icon"
    {
      passthru = { fileName = cfg.icon.fileName; };
    } ''
    local target="$out/share/antob-icons/user/${cfg.name}"
    mkdir -p "$target"

    cp ${cfg.icon} "$target/${cfg.icon.fileName}"
  '';
in
{
  options.antob.user = with types; {
    name = mkOpt str "short" "The name to use for the user account.";
    fullName = mkOpt str "Tobias Lindholm" "The full name of the user.";
    email = mkOpt str "tobias.lindholm@antob.se" "The email of the user.";
    icon = mkOpt (nullOr package) defaultIcon
      "The profile picture to use for the user.";
    hashedPassword = mkOpt str
      "$y$j9T$wMqZpnWm/J7vImr/tGECw0$.U4rNWDVPeUz2cvOD8YOa23QaCf.AY6w8A0IIHm1itA"
      "Hash of the user password password. To generate a hashed password run `mkpasswd`.";
    autoLogin = mkBoolOpt false "Whether or not to autologin user.";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
    extraOptions = mkOpt attrs { }
      "Extra options passed to <option>users.users.<name></option>.";
  };

  config = {
    antob = {
      tools = {
        git = enabled;
        zsh = enabled;
        starship = enabled;
        eza = enabled;
        direnv = enabled;
        devenv = enabled;
        zellij = enabled;
        flameshot = enabled;
      };

      cli-apps = {
        neovim = enabled;
        helix = enabled;
        tmux = enabled;
      };

      security.gpg = enabled;

      virtualisation.podman = enabled;

      # debug.trackChanges = enabled;

      home.file = {
        ".face".source = cfg.icon;
        "Pictures/${
          cfg.icon.fileName or (builtins.baseNameOf cfg.icon)
        }".source = cfg.icon;
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
            ".ssh/safe"
            ".local/share/password-store"
          ];
        };

        safe.directories = [
          "/home/${cfg.name}/Projects"
          "/home/${cfg.name}/Documents"
          "/home/${cfg.name}/Pictures"
          "/home/${cfg.name}/Videos"
          "/home/${cfg.name}/Music"
        ];
      };
    };

    antob.home.extraOptions.programs = {
      zoxide = {
        enable = true;
        options = [ "--cmd cd" ];
        enableZshIntegration = true;
      };

      bat = {
        enable = true;
        config.theme = "ansi";
      };

      password-store.enable = true;

      tealdeer.enable = true;
    };

    environment.shellAliases = {
      cat = "bat -p";
      http = "xh";
      https = "xhs";
    };

    environment.systemPackages = with pkgs; [ propagatedIcon ];

    # services.getty.autologinUser = mkIf cfg.autoLogin cfg.name;

    # Enable passwordless sudo for wheel group
    security.sudo.wheelNeedsPassword = false;

    users = {
      mutableUsers = false;
      users.${cfg.name} = {
        isNormalUser = true;

        inherit (cfg) name hashedPassword;

        home = "/home/${cfg.name}";
        group = "users";

        shell = mkIf config.antob.tools.zsh.enable pkgs.zsh;

        extraGroups = [ "wheel" ] ++ cfg.extraGroups;
      } // cfg.extraOptions;
    };
  };
}
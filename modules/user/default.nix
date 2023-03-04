{ options, config, pkgs, lib, ... }:

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

    passthru = { fileName = defaultIconFileName; };
  };
  propagatedIcon = pkgs.runCommandNoCC "propagated-icon"
    { passthru = { fileName = cfg.icon.fileName; }; }
    ''
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
    initialPassword = mkOpt str "password" "The initial password to use when the user is first created.";
    autoLogin = mkBoolOpt false "Whether or not to autologin user.";
    icon = mkOpt (nullOr package) defaultIcon
      "The profile picture to use for the user.";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
    extraOptions = mkOpt attrs { }
      "Extra options passed to <option>users.users.<name></option>.";
  };

  config = {
    environment.systemPackages = with pkgs; [
      propagatedIcon
    ];

    programs.zsh = {
      enable = true;
      autosuggestions.enable = true;
      # histFile = "$XDG_CACHE_HOME/zsh.history";
    };

    antob.home = {
      file = {
        # "Desktop/.keep".text = "";
        # "Documents/.keep".text = "";
        # "Downloads/.keep".text = "";
        # "Music/.keep".text = "";
        # "Pictures/.keep".text = "";
        # "Videos/.keep".text = "";
        # "work/.keep".text = "";
        ".face".source = cfg.icon;
        "Pictures/${
          cfg.icon.fileName or (builtins.baseNameOf cfg.icon)
        }".source = cfg.icon;
      };

      extraOptions = {
        home.shellAliases =
          let treeIgnore = "'cache|log|logs|node_modules|vendor|.git'";
          in
          {
            ".." = "cd ..";
            ls = "${pkgs.exa}/bin/exa --group-directories-first";
            la = "ls -a";
            l = "ls --git -l";
            ll = "ls --git -al";
            lt = "ls --tree -D -L 2 -I ${treeIgnore}";
            ltt = "ls --tree -D -L 3 -I ${treeIgnore}";
            lttt = "ls --tree -D -L 4 -I ${treeIgnore}";
            ltttt = "ls --tree -D -L 5 -I ${treeIgnore}";
          };

        programs = {
          starship = {
            enable = true;
            settings = {
              format = "$username$hostname$directory$git_branch$git_commit$git_state$git_status$cmd_duration$line_break$battery$status$character";
            };
          };

          zsh = {
            enable = true;
            enableCompletion = true;
            enableAutosuggestions = true;
            enableSyntaxHighlighting = true;

            initExtra = ''
              # Use vim bindings.
              set -o vi

              # Improved vim bindings.
              source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
            '';

            oh-my-zsh = {
              enable = true;
              plugins = [ "git" ];
            };
          };
        };
      };
    };

    services.getty.autologinUser = mkIf cfg.autoLogin cfg.name;

    users.users.${cfg.name} = {
      isNormalUser = true;

      inherit (cfg) name initialPassword;

      home = "/home/${cfg.name}";
      group = "users";

      shell = pkgs.zsh;

      # Arbitrary user ID to use for the user. Since I only
      # have a single user on my machines this won't ever collide.
      # However, if you add multiple users you'll need to change this
      # so each user has their own unique uid (or leave it out for the
      # system to select).
      uid = 1000;

      extraGroups = [ "wheel" ] ++ cfg.extraGroups;
    } // cfg.extraOptions;
  };
}


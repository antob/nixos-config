{ options, config, pkgs, lib, ... }:

with lib;
let
  mkOpt = type: default: description:
    mkOption { inherit type default description; };
  mkBoolOpt = mkOpt types.bool;
  enabled = { enable = true; };

  cfg = config.host.tools.git;
  # gpg = config.host.security.gpg;
  user = config.host.user;
in {
  options.host.tools.git = with types; {
    enable = mkBoolOpt false "Whether or not to install and configure git.";
    userName = mkOpt types.str user.fullName "The name to configure git with.";
    userEmail = mkOpt types.str user.email "The email to configure git with.";
    signingKey =
      mkOpt types.str "9762169A1B35EA68" "The key ID to sign commits with.";
  };

  config = mkIf cfg.enable {
    # environment.systemPackages = with pkgs; [ git ];

    programs.git = {
      enable = true;
      inherit (cfg) userName userEmail;
      lfs = enabled;
      signing = {
        key = cfg.signingKey;
        # signByDefault = mkIf gpg.enable true;
      };
      extraConfig = {
        init = { defaultBranch = "main"; };
        pull = { rebase = true; };
        push = { autoSetupRemote = true; };
        core = { whitespace = "trailing-space,space-before-tab"; };
      };
    };
  };
}

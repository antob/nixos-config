{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.tools.git;
  # gpg = config.antob.security.gpg;
  user = config.antob.user;
  colors = config.antob.color-scheme.colors;
in
{
  options.antob.tools.git = with types; {
    enable = mkEnableOption "Whether or not to install and configure git.";
    userName = mkOpt types.str user.fullName "The name to configure git with.";
    userEmail = mkOpt types.str user.email "The email to configure git with.";
    signingKey = mkOpt types.str "tobias.lindholm@antob.se" "The key ID to sign commits with.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      gitui
      lazygit
    ];

    antob.home.extraOptions = {
      xdg.configFile."lazygit/config.yml".text = ''
        gui:
          showFileTree: false
          showRandomTip: false
          showCommandLog: false
          nerdFontsVersion: "3"
          border: single
          theme:
            selectedLineBgColor:
              - '#${colors.base12}'
            inactiveBorderColor:
              - '#${colors.base12}'
      '';

      programs.git = {
        enable = true;
        inherit (cfg) userName userEmail;
        lfs = enabled;

        signing = {
          key = cfg.signingKey;
          signByDefault = mkIf config.antob.security.gpg.enable true;
        };

        aliases.hist = "log --graph --pretty=format:'%Cred%h %cd%Creset |%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=short";

        extraConfig = {
          init = {
            defaultBranch = "main";
          };
          pull = {
            rebase = true;
          };
          push = {
            autoSetupRemote = true;
          };
          core = {
            whitespace = "trailing-space,space-before-tab";
            editor = "nvim";
            excludesfile = "~/.gitexcludes";
          };
          merge = {
            conflictstyle = "diff3";
          };
          credential = {
            helper = "cache";
          };
        };

        attributes = [
          "*.c     diff=cpp"
          "*.h     diff=cpp"
          "*.c++   diff=cpp"
          "*.h++   diff=cpp"
          "*.cpp   diff=cpp"
          "*.hpp   diff=cpp"
          "*.cc    diff=cpp"
          "*.hh    diff=cpp"
          "*.m     diff=objc"
          "*.mm    diff=objc"
          "*.cs    diff=csharp"
          "*.css   diff=css"
          "*.html  diff=html"
          "*.xhtml diff=html"
          "*.ex    diff=elixir"
          "*.exs   diff=elixir"
          "*.go    diff=golang"
          "*.php   diff=php"
          "*.pl    diff=perl"
          "*.py    diff=python"
          "*.md    diff=markdown"
          "*.rb    diff=ruby"
          "*.rake  diff=ruby"
          "*.rs    diff=rust"
          "*.lisp  diff=lisp"
          "*.el    diff=lisp"
        ];
      };

      programs.zsh.initContent = mkIf config.antob.tools.fzf.enable (
        mkOrder 200 ''
          source ${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh
        ''
      );

      home.file = {
        ".gitexcludes".source = ./.gitexcludes;
      };
    };

    environment.shellAliases = {
      gh = "git hist";
    };
  };
}

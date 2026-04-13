{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
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
      delta
    ];

    antob.home.extraOptions = {
      xdg.configFile."lazygit/config.yml".text = /* yaml */ ''
        gui:
          showFileTree: false
          showRandomTip: false
          showCommandLog: false
          nerdFontsVersion: "3"
          border: single
          theme:
            selectedLineBgColor:
              - "#${colors.base12}"
            inactiveBorderColor:
              - "#${colors.base12}"
        git:
          autoFetch: false
          overrideGpg: true
          pagers:
            - pager: delta --dark --paging=never
        update:
          method: never
        promptToReturnFromSubprocess: false
      '';

      programs.git = {
        enable = true;
        lfs = enabled;

        signing = {
          key = cfg.signingKey;
          format = "openpgp";
          signByDefault = mkIf config.antob.security.gpg.enable true;
        };

        settings = {
          user = {
            name = cfg.userName;
            email = cfg.userEmail;
          };

          alias.hist = "log --graph --pretty=format:'%Cred%h %cd%Creset |%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=short";

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
            pager = "delta";
          };
          merge = {
            conflictstyle = "zdiff3";
          };
          credential = {
            helper = "cache";
          };
          interactive = {
            diffFilter = "delta --color-only";
          };
          delta = {
            navigate = true; # use n and N to move between diff sections
            syntax-theme = "OneHalfDark";

            features = "side-by-side line-numbers decorations";
            plus-style = "syntax '#003800'";
            minus-style = "syntax '#3f0001'";

            decorations = {
              commit-decoration-style = "yellow ul ol";
              file-style = "yellow";
              file-decoration-style = "yellow ul";
              hunk-header-file-style = "yellow";
              hunk-header-line-number-style = "yellow";
              hunk-header-decoration-style = "#444444 ul";
              file-added-label = "added: ";
              file-copied-label = "copied: ";
              file-modified-label = "modified: ";
              file-removed-label = "removed: ";
              file-renamed-label = "renamed: ";
            };

            line-numbers = {
              line-numbers-left-style = "#444444";
              line-numbers-right-style = "#444444";
            };
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

    antob.persistence.home.directories = [ ".local/state/lazygit" ];

    environment.shellAliases = {
      gh = "git hist";
      gb = "git branch";
      gco = "git checkout";
      gc = "git commit --verbose";
      gca = "git commit --verbose --all";
      gd = "git diff";
      gp = "git push";
      gst = "git status";
      gg = "lazygit";
    };
  };
}

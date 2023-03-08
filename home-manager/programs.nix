{
  programs = {
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    bat = {
      enable = true;
      config.theme = "ansi";
    };
    zsh.shellAliases = { cat = "bat -p"; };

    librewolf = {
      enable = true;
      settings = {
        "privacy.clearOnShutdown.history" = false;
        "privacy.clearOnShutdown.downloads" = false;
      };
    };
  };
}

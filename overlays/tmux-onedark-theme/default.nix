{ channels, ... }:

final: prev: {
  tmux-onedark-theme = prev.tmuxPlugins.onedark-theme.overrideAttrs (oldAttrs: {
    version = "custom-2024-10-15";
    src = prev.fetchFromGitHub {
      owner = "antob";
      repo = "tmux-onedark-theme";
      rev = "103afe723f677d90df2da49fb7e2790834a38c7e";
      sha256 = "sha256-H1KPrLQETUh3lUl6u0FwP9Ej/pzf82ZhD4y4F9J9KSg=";
    };
  });
}

{ channels, ... }:

final: prev: {
  tmux-onedark-theme = prev.tmuxPlugins.onedark-theme.overrideAttrs (oldAttrs: {
    version = "custom-2023-04-27";
    src = prev.fetchFromGitHub {
      owner = "antob";
      repo = "tmux-onedark-theme";
      rev = "7959af688cb0661532ea06398a78c2f886b92219";
      sha256 = "sha256-THWqq8xyroC/PBPRX63dXo/55JXxaEFWQd1qy1pfH3Y=";
    };
  });
}

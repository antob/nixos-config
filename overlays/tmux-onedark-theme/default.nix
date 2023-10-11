{ channels, ... }:

final: prev: {
  tmux-onedark-theme = prev.tmuxPlugins.onedark-theme.overrideAttrs (oldAttrs: {
    version = "custom-2023-04-27";
    src = prev.fetchFromGitHub {
      owner = "antob";
      repo = "tmux-onedark-theme";
      rev = "35ef429502f618765ea3800534a5a8c63ce7149f";
      sha256 = "sha256-ZsrHW1MhbRDW8oYjPP4W7kY6RkMbafjggrEqgVq0Db0=";
    };
  });
}

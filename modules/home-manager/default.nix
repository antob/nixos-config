{
  user = import ./user.nix;
  fonts = import ./fonts.nix;
  git = import ./git.nix;
  neovim = import ./neovim.nix;
  zsh = import ./zsh.nix;
  starship = import ./starship.nix;
  exa = import ./exa.nix;
}

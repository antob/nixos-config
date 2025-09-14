{ pkgs, ... }:
{
  extraPackages = with pkgs; [
    nodePackages.bash-language-server
    emmet-language-server
    vscode-langservers-extracted
    nil
    shfmt
    stylua
  ];
}

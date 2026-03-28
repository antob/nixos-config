{
  pkgs ? import <nixpkgs> { },
  ...
}:
{
  gnome-shell-extension-expand-shutdown-menu =
    pkgs.callPackage ./gnome-shell-extension-expand-shutdown-menu
      { };
  pinentry-dmenu = pkgs.callPackage ./pinentry-dmenu { };
  pinentry-tofi = pkgs.callPackage ./pinentry-tofi { };
  pinentry-walker = pkgs.callPackage ./pinentry-walker { };
  sfns-display-font = pkgs.callPackage ./sfns-display-font { };
  zsh-window-title = pkgs.callPackage ./zsh-window-title { };
  wlr-dpms = pkgs.callPackage ./wlr-dpms { };
  herb-tools = pkgs.callPackage ./herb-tools { };
  m68k-lsp-server = pkgs.callPackage ./m68k-lsp-server { };
  pi-coding-agent = pkgs.callPackage ./pi-coding-agent { };
  agent-browser = pkgs.callPackage ./agent-browser { };
}

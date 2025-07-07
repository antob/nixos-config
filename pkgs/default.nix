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
  sfns-display-font = pkgs.callPackage ./sfns-display-font { };
  zsh-window-title = pkgs.callPackage ./zsh-window-title { };
}

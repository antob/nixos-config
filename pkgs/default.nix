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
  soundcloudpy = pkgs.callPackage ./soundcloudpy { };
}

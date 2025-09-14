{ pkgs }:
[
  (pkgs.callPackage ./cmd-screenshot.nix { })
  (pkgs.callPackage ./cmd-launch-webapp.nix { })
  (pkgs.callPackage ./cmd-lock-screen.nix { })
  (pkgs.callPackage ./cmd-screensaver.nix { })
  (pkgs.callPackage ./cmd-launch-screensaver.nix { })
]

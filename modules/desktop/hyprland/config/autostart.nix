{
  pkgs,
  lib,
}:
let
  bitwarden-resize = lib.getExe (
    pkgs.callPackage ../scripts/hypr-bitwarden-resize.nix { inherit pkgs; }
  );
in
''
  exec-once = uwsm app -- ${pkgs.swayosd}/bin/swayosd-server
  exec-once = ${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular --reconnect-tries 0
  exec-once = ${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store
  exec-once = ${bitwarden-resize}
''

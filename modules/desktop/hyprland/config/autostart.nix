{ pkgs, ... }:
''
  exec-once = uwsm app -- ${pkgs.swayosd}/bin/swayosd-server
  exec-once = uwsm app -- ${pkgs.swaybg}/bin/swaybg -i ~/Pictures/Wallpapers/Omarchy-Backgrounds/1-scenery-pink-lakeside-sunset-lake-landscape-scenic-panorama-7680x3215-144.png -m fill
  exec-once = ${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular --reconnect-tries 0
  exec-once = ${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store
''

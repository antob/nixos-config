{
  lib,
  config,
  pkgs,
}:
import ./autostart.nix { inherit pkgs; }
+ import ./bindings { inherit lib config pkgs; }
+ import ./windows.nix { }
+ import ./workspaces.nix { }
+ import ./envs.nix { }
+ import ./input.nix { }
+ import ./monitors.nix { }
+ import ./looknfeel.nix { inherit config; }
+ import ./groups.nix { inherit config; }
+ import ./plugins.nix { }

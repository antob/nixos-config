{
  lib,
  config,
  pkgs,
}:
let
  dm-firefox-profile = lib.getExe (
    pkgs.callPackage ../../../scripts/dm-firefox-profile.nix { inherit config; }
  );
in
''
  $terminal = uwsm app -- alacritty
  $browser = uwsm app -- firefox
  $chromium = uwsm app -- chromium --app=

  # Apps
  bindd = SUPER, RETURN, Terminal, exec, ${
    if config.antob.cli-apps.tmux.enable then "$terminal -e tmux-attach-unused" else "$terminal"
  }
  bindd = SUPER SHIFT, RETURN, Terminal, exec, $terminal
  bindd = SUPER, E, File manager, exec, uwsm app -- nautilus --new-window
  bindd = SUPER, W, Web browser, exec, $browser
  bindd = SUPER SHIFT, W, Select Firefox profile, exec, ${dm-firefox-profile}
  bindd = SUPER, N, Neovim, exec, $terminal -e nvim
  bindd = SUPER, T, Activity, exec, $terminal --class=TUI.float.lg -e ${lib.getExe pkgs.bottom}
  bindd = SUPER, B, Bluetooth, exec, $terminal --class=TUI.float -e bluetui
  bindd = SUPER, O, Obsidian, exec, uwsm app -- obsidian -disable-gpu
  bindd = SUPER SHIFT, P, Displays, exec, uwsm app -- ${lib.getExe pkgs.nwg-displays}
''
+ import ./media.nix { inherit pkgs; }
+ import ./tiling.nix { }
+ import ./utilities.nix { inherit pkgs lib; }
+ import ./plugins.nix { }

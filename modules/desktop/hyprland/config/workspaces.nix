{ }:
''
  # No gaps and no borders when workspace has only 1 tiled window
  workspace = w[tv1], gapsout:0, gapsin:0, border:false, rounding:false

  # No gaps and no borders when workspace has a maximized window
  workspace = f[1], gapsout:0, gapsin:0, border:false, rounding:false

  # Set by nwg-displays
  source = ~/.config/hypr/workspaces.conf
''

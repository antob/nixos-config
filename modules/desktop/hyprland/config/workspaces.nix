{ }:
''
  # No gaps and no borders when workspace has only 1 tiled window
  workspace = w[tv1], gapsout:0, gapsin:0, border:false, rounding:false

  # No gaps and no borders when workspace has a maximized window
  workspace = f[1], gapsout:0, gapsin:0, border:false, rounding:false

  #windowrule = bordersize 0, floating:0, onworkspace:w[tv1]
  #windowrule = rounding 0, floating:0, onworkspace:w[tv1]
  #windowrule = bordersize 0, floating:0, onworkspace:f[1]
  #windowrule = rounding 0, floating:0, onworkspace:f[1]

  # Set by nwg-displays
  source = ~/.config/hypr/workspaces.conf
''

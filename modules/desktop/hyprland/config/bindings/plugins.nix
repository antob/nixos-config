{ }:
''
  # Move focus with SUPER + arrow keys
  bindd = SUPER SHIFT, left, Move window to left col, layoutmsg, movewindowto l
  bindd = SUPER SHIFT, right, Move window to right col, layoutmsg, movewindowto r
  bindd = SUPER SHIFT, up, Move window up col, layoutmsg, movewindowto u
  bindd = SUPER SHIFT, down, Move window down col, layoutmsg, movewindowto d

  # Resize active column
  bindd = SUPER, minus, Decrease column width, layoutmsg, colresize -0.1
  bindd = SUPER, equal, Increase column width, layoutmsg, colresize +0.1
  bindd = SUPER SHIFT, equal, Maximize column width, layoutmsg, fit active

  # Scroll the workspace horizontally
  bindd = SUPER CTRL, left, Scroll workspace left, layoutmsg, move -100
  bindd = SUPER CTRL, right, Scroll workspace right, layoutmsg, move +100
''

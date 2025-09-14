{ }:
''
  # Change layout
  bindd = SUPER ALT, M, Switch to master layout, exec, hyprctl keyword general:layout master
  bindd = SUPER ALT, D, Switch to dwindle layout, exec, hyprctl keyword general:layout dwindle
  bindd = SUPER ALT, S, Switch to scrolling layout, exec, hyprctl keyword general:layout scrolling

  # Close windows
  bindd = SUPER, Q, Close active window, killactive,

  # Control tiling
  bindd = SUPER, V, Toggle floating, togglefloating,
  bindd = SUPER, F, Full screen, fullscreen
  bindd = SUPER, M, Maximize window, fullscreen, 1

  # Move focus with SUPER + arrow keys
  #bindd = SUPER, left, Move focus left, cyclenext, prev
  #bindd = SUPER, right, Move focus right, cyclenext
  bindd = SUPER, left, Move focus left, movefocus, l
  bindd = SUPER, right, Move focus right, movefocus, r
  bindd = SUPER, up, Move focus up, movefocus, u
  bindd = SUPER, down, Move focus down, movefocus, d

  # Switch workspaces with SUPER + [0-9]
  bindd = SUPER, 1, Switch to workspace 1, workspace, 1
  bindd = SUPER, 2, Switch to workspace 2, workspace, 2
  bindd = SUPER, 3, Switch to workspace 3, workspace, 3
  bindd = SUPER, 4, Switch to workspace 4, workspace, 4
  bindd = SUPER, 5, Switch to workspace 5, workspace, 5
  bindd = SUPER, 6, Switch to workspace 6, workspace, 6
  bindd = SUPER, 7, Switch to workspace 7, workspace, 7
  bindd = SUPER, 8, Switch to workspace 8, workspace, 8
  bindd = SUPER, 9, Switch to workspace 9, workspace, 9

  # Move active window to a workspace with SUPER + SHIFT + [0-9]
  bindd = SUPER SHIFT, 1, Move window to workspace 1, movetoworkspace, 1
  bindd = SUPER SHIFT, 2, Move window to workspace 2, movetoworkspace, 2
  bindd = SUPER SHIFT, 3, Move window to workspace 3, movetoworkspace, 3
  bindd = SUPER SHIFT, 4, Move window to workspace 4, movetoworkspace, 4
  bindd = SUPER SHIFT, 5, Move window to workspace 5, movetoworkspace, 5
  bindd = SUPER SHIFT, 6, Move window to workspace 6, movetoworkspace, 6
  bindd = SUPER SHIFT, 7, Move window to workspace 7, movetoworkspace, 7
  bindd = SUPER SHIFT, 8, Move window to workspace 8, movetoworkspace, 8
  bindd = SUPER SHIFT, 9, Move window to workspace 9, movetoworkspace, 9

  # Tab between workspaces
  bindd = SUPER, TAB, Next workspace, workspace, e+1
  bindd = SUPER SHIFT, TAB, Previous workspace, workspace, e-1

  # Swap active window with the one next to it with SUPER + SHIFT + arrow keys
  bindd = SUPER SHIFT, left, Swap window to the left, swapwindow, l
  bindd = SUPER SHIFT, right, Swap window to the right, swapwindow, r
  bindd = SUPER SHIFT, up, Swap window up, swapwindow, u
  bindd = SUPER SHIFT, down, Swap window down, swapwindow, d

  # Swap active window with master
  bindd = SUPER, BackSpace, Swap window with master, layoutmsg, swapwithmaster auto

  # Cycle through applications on active workspace
  bindd = ALT, Tab, Cycle to next window, cyclenext
  bindd = ALT SHIFT, Tab, Cycle to prev window, cyclenext, prev
  bindd = ALT, Tab, Reveal active window on top, bringactivetotop
  bindd = ALT SHIFT, Tab, Reveal active window on top, bringactivetotop

  # Resize active window
  bindd = SUPER, MINUS, Expand window left, resizeactive, -100 0
  bindd = SUPER, EQUAL, Shrink window left, resizeactive, 100 0
  bindd = SUPER SHIFT, MINUS, Shrink window up, resizeactive, 0 -100
  bindd = SUPER SHIFT, EQUAL, Expand window down, resizeactive, 0 100

  # Move/resize windows with mainMod + LMB/RMB and dragging
  bindmd = SUPER, mouse:272, Move window, movewindow
  bindmd = SUPER, mouse:273, Resize window, resizewindow

  # Focus monitor
  bindd = ALT, 1, Focus monitor 1, focusmonitor, 0
  bindd = ALT, 2, Focus monitor 2, focusmonitor, 1
  bindd = ALT, 3, Focus monitor 3, focusmonitor, 2

  # Move active workspace to monitor
  bindd = ALT SHIFT, 1, Move workspace to monitor 1, movecurrentworkspacetomonitor, 0
  bindd = ALT SHIFT, 2, Move workspace to monitor 2, movecurrentworkspacetomonitor, 1
  bindd = ALT SHIFT, 3, Move workspace to monitor 3, movecurrentworkspacetomonitor, 2

  # Groups
  bindd = SUPER, G, Toggle the current active window into a group, togglegroup
  bindd = SUPER ALT, Right, Switch to the next window in a group, changegroupactive, f
  bindd = SUPER ALT, Left, Switch to the previous window in a group, changegroupactive, b
  bindd = SUPER ALT SHIFT, Right, Move the active window into right group, movewindoworgroup, r
  bindd = SUPER ALT SHIFT, Left, Move the active window into left group, movewindoworgroup, l
''

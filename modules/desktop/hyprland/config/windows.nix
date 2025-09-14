{ }:
''
  # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
  windowrule = suppressevent maximize, class:.*

  # Just dash of opacity by default
  windowrule = opacity 0.97 0.9, class:.*

  # Fix some dragging issues with XWayland
  windowrule = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0

  # Remove 1px border around hyprshot screenshots
  layerrule = noanim, selection

  # No animations on Walker menues
  layerrule = noanim, walker

  # Apps on specific workspaces
  windowrule = workspace 2,class:(firefox)
  windowrule = workspace 3,class:(code)
  windowrule = workspace 5,class:(obsidian|Slack|chromium-browser)

  # Floating windows
  windowrule = float, tag:floating-window
  windowrule = center, tag:floating-window
  windowrule = size 800 600, tag:floating-window
  windowrule = float, tag:floating-window-lg
  windowrule = center, tag:floating-window-lg
  windowrule = size 1100 700, tag:floating-window-lg

  windowrule = tag +floating-window, class:(Wiremix|org.gnome.NautilusPreviewer|com.gabm.satty|About|TUI.float)
  windowrule = tag +floating-window, class:(xdg-desktop-portal-gtk|DesktopEditors|org.gnome.Nautilus), title:^(Open.*Files?|Open Folder|Save.*Files?|Save.*As|Save|All Files)
  windowrule = tag +floating-window-lg, class:(TUI.float.lg|nwg-displays)

  # Fullscreen screensaver
  windowrule = fullscreen, class:Screensaver

  # No transparency on media windows
  windowrule = opacity 1 1, class:^(zoom|vlc|mpv|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$

  # Do not animate fullscreen windows
  windowrule = noanim, fullscreen:1
''

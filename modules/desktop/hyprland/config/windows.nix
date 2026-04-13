{ }:
''
  # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
  windowrule = suppress_event maximize, match:class .*

  # Just dash of opacity by default
  windowrule = opacity 1.0 0.95, match:class .*

  # Fix some dragging issues with XWayland
  # windowrule = no_focus on,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0

  # Remove 1px border around hyprshot screenshots
  layerrule = no_anim on, match:namespace selection

  # No animations on rofi menues
  layerrule = no_anim on, match:namespace rofi

  # Apps on specific workspaces
  windowrule = workspace 2, match:class (firefox)
  windowrule = workspace 3, match:class (code)
  windowrule = workspace 5, match:class (obsidian|Slack|chromium-browser)

  # Floating windows
  windowrule = float on, match:tag floating-window
  windowrule = center on, match:tag floating-window
  windowrule = size 800 600, match:tag floating-window
  windowrule = float on, match:tag floating-window-lg
  windowrule = center on, match:tag floating-window-lg
  windowrule = size 1100 700, match:tag floating-window-lg

  windowrule = tag +floating-window, match:class (Wiremix|org.gnome.NautilusPreviewer|com.gabm.satty|About|TUI.float)
  windowrule = tag +floating-window, match:class (xdg-desktop-portal-gtk|DesktopEditors|org.gnome.Nautilus), match:title ^(Open.*Files?|Open Folder|Save.*Files?|Save.*As|Save|All Files)
  windowrule = tag +floating-window-lg, match:class (TUI.float.lg|nwg-displays|X64)

  # Fullscreen screensaver
  windowrule = fullscreen on, match:class Screensaver

  # No transparency on specific windows
  windowrule = opacity 1 1, match:class ^(zoom|vlc|mpv|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer|X64)$
  windowrule = opacity 1 1, match:class ^(firefox|Alacritty)$

  # fs-uae
  windowrule = float on, size 960 768, opacity 1 1, match:class fs-uae

  # Do not animate fullscreen windows
  windowrule = no_anim on, match:fullscreen 1
''

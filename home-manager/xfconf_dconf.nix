{ config, ... }:

{
  xfconf = {
    enable = true;
    settings = {
      keyboards = {
        "Default/KeyRepeat/Delay" = 200;
        "Default/KeyRepeat/Rate" = 40;
      };
      xsettings = { "Gtk/CursorThemeName" = config.gtk.cursorTheme.name; };
      displays = {
        "ActiveProfile" = "Default";
        "Default/Virtual-1" = "Virtual-1";
        "Default/Virtual-1/Active" = true;
        "Default/Virtual-1/Resolution" = "2560x1600";
        "Default/Virtual-1/RefreshRate" = "59.98658779075852";
        "Default/Virtual-1/Primary" = true;
        "Default/Virtual-1/Scale/X" = 1.0;
        "Default/Virtual-1/Scale/Y" = 1.0;
        "Default/Virtual-1/Position/X" = 0;
        "Default/Virtual-1/Position/Y" = 0;
        "Default/Virtual-1/Rotation" = 0;
        "Default/Virtual-1/Reflection" = 0;
      };
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      cursor-theme = config.gtk.cursorTheme.name;
    };
  };
}

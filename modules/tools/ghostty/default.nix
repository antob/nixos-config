{ config, lib, ... }:

with lib;
let
  cfg = config.antob.tools.ghostty;
  colors = config.antob.color-scheme.colors;
in
{
  options.antob.tools.ghostty = with types; {
    enable = mkEnableOption "Enable Ghostty";
    fontSize = mkOpt int 12 "Font size.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions.programs.ghostty = {
      enable = true;
      enableZshIntegration = true;
      systemd.enable = true;
      clearDefaultKeybinds = true;

      settings = {
        theme = "TokyoNight Night";
        font-family = "Hack Nerd Font";
        font-size = cfg.fontSize;
        cursor-style = "bar";
        cursor-style-blink = false;
        mouse-hide-while-typing = true;
        split-divider-color = "#${colors.base0C}";
        split-preserve-zoom = "navigation";
        window-padding-x = 8;
        window-padding-y = 5;
        window-inherit-working-directory = true;
        tab-inherit-working-directory = true;
        split-inherit-working-directory = true;
        window-decoration = "none";
        window-show-tab-bar = "auto";
        resize-overlay = "never";
        quit-after-last-window-closed = true;
        bell-features = "no-audio";
        auto-update = "off";
        gtk-toolbar-style = "flat";
        gtk-wide-tabs = false;

        keybind = [
          "ctrl+shift+c=copy_to_clipboard"
          "ctrl+shift+v=paste_from_clipboard"
          "ctrl+shift++=increase_font_size:1"
          "ctrl+shift+_=decrease_font_size:1"
          "ctrl+shift+0=reset_font_size"
          "ctrl+shift+f=start_search"
          "ctrl+shift+home=scroll_to_top"
          "ctrl+shift+end=scroll_to_bottom"
          "page_up=scroll_page_up"
          "page_down=scroll_page_down"
          "ctrl+shift+t=new_tab"
          "ctrl+shift+alt+t=close_tab"
          "ctrl+shift+[=previous_tab"
          "ctrl+shift+]=next_tab"
          "ctrl+shift+page_up=move_tab:-1"
          "ctrl+shift+page_down=move_tab:1"
          "ctrl+shift+$=prompt_tab_title"
          "ctrl+shift+\"=new_split:right"
          "ctrl+shift+:=new_split:down"
          "ctrl+shift+enter=new_split:auto"
          "ctrl+shift+left=goto_split:left"
          "ctrl+shift+right=goto_split:right"
          "ctrl+shift+up=goto_split:up"
          "ctrl+shift+down=goto_split:down"
          "ctrl+shift+m=toggle_split_zoom"
          "ctrl+shift+alt+left=resize_split:left,50"
          "ctrl+shift+alt+right=resize_split:right,50"
          "ctrl+shift+alt+up=resize_split:up,10"
          "ctrl+shift+alt+down=resize_split:down,10"
          "ctrl+shift+\\=equalize_splits"
          "ctrl+shift+alt+r=reload_config"
          "ctrl+shift+p=toggle_command_palette"
          "ctrl+shift+u=undo"
          "ctrl+shift+r=redo"
        ];

        # keybind = ctrl+shift+c=copy_to_clipboard
        # keybind = ctrl+shift+v=paste_from_clipboard
        # keybind = ctrl+shift+==increase_font_size
        # keybind = ctrl+shift+-=decrease_font_size
        # keybind = ctrl+shift+0=reset_font_size
        # keybind = ctrl+shift+/=search
        # keybind = ctrl+shift+home=scroll_to_top
        # keybind = ctrl+shift+end=scroll_to_bottom
        # keybind = page_up=scroll_page_up
        # keybind = page_down=scroll_page_down
        # keybind = ctrl+shift+d=scroll_page_fractional:0.5
        # keybind = ctrl+shift+u=scroll_page_fractional:-0.5
        # keybind = ctrl+shift+t=new_tab
        # keybind = ctrl+shift+alt+t=close_tab
        # keybind = ctrl+shift+[=previous_tab
        # keybind = ctrl+shift+]=next_tab
        # keybind = ctrl+shift+page_up=move_tab:-1
        # keybind = ctrl+shift+page_down=move_tab:1
        # keybind = ctrl+shift+$=prompt_tab_title
        # keybind = ctrl+shift+'=new_split:right
        # keybind = ctrl+shift+"=new_split:down
        # keybind = ctrl+shift+enter=new_split:auto
        # keybind = ctrl+shift+left=goto_split:left
        # keybind = ctrl+shift+right=goto_split:right
        # keybind = ctrl+shift+up=goto_split:up
        # keybind = ctrl+shift+down=goto_split:down
        # keybind = ctrl+shift+m=toggle_split_zoom
        # keybind = ctrl+shift+alt+left=resize_split:left,10
        # keybind = ctrl+shift+alt+right=resize_split:right,10
        # keybind = ctrl+shift+up=resize_split:up,10
        # keybind = ctrl+shift+down=resize_split:down,10
        # keybind = ctrl+shift+\=equalize_splits
        # keybind = ctrl+shift+alt+r=reload_config
        # keybind = ctrl+shift+p=toggle_command_palette
        # keybind = ctrl+shift+u=undo
        # keybind = ctrl+shift+r=redo
      };
    };
  };
}

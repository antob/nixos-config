{ config, lib, ... }:

with lib;
let
  cfg = config.antob.tools.wezterm;
  colors = config.antob.color-scheme.colors;
in
{
  options.antob.tools.wezterm = with types; {
    enable = mkEnableOption "Enable wezterm";
    fontSize = mkOpt int 12 "Font size.";
  };

  config = mkIf cfg.enable {
    antob.persistence = {
      home.directories = [
        ".local/share/wezterm"
        ".cache/wezterm"
      ];
    };

    antob.home.extraOptions.programs.wezterm = {
      enable = true;
      enableZshIntegration = true;
      extraConfig = /* lua */ ''
        local wezterm = require("wezterm")
        local config = wezterm.config_builder()
        local act = wezterm.action

        -- Customize the Tokyo Night theme
        local custom_theme = wezterm.color.get_builtin_schemes()["Tokyo Night"]
        -- custom_theme.selection_bg = "#${colors.base04}"
        custom_theme.selection_fg = "none"
        custom_theme.selection_bg = "rgba(90% 90% 90% 25%)"

        -- General settings
        config.color_schemes = {
          ["Custom Tokyo Night"] = custom_theme,
        }
        config.color_scheme = "Custom Tokyo Night"
        config.font = wezterm.font("Hack Nerd Font")
        config.font_size = tonumber("${toString cfg.fontSize}")
        config.window_decorations = "NONE"
        config.window_padding = {
          left = 12,
          right = 12,
          top = 9,
          bottom = 9,
        }
        config.audible_bell = "Disabled"
        config.check_for_updates = false
        config.scrollback_lines = 10000
        config.default_cursor_style = "SteadyBar"
        config.cursor_blink_rate = 0
        config.command_palette_bg_color = "#${colors.base13}"
        config.command_palette_fg_color = "#${colors.base06}"
        config.window_close_confirmation = "NeverPrompt"
        config.enable_tab_bar = false
        config.enable_kitty_keyboard = true

        -- Key bindings
        config.disable_default_key_bindings = true
        config.keys = {
          {
            key = "l",
            mods = "CTRL|SHIFT",
            action = act.SendString("\u{E000}"),
          },
          {
            key = "Enter",
            mods = "CTRL|SHIFT",
            action = act.SendString("\u{E010}"),
          },
          {
            key = "m",
            mods = "CTRL|SHIFT",
            action = act.SendString("\u{E011}"),
          },
          {
            key = "t",
            mods = "CTRL|SHIFT",
            action = act.SendString("\u{E020}"),
          },
          {
            key = "{",
            mods = "CTRL|SHIFT",
            action = act.SendString("\u{E021}"),
          },
          {
            key = "}",
            mods = "CTRL|SHIFT",
            action = act.SendString("\u{E022}"),
          },
          {
            key = "{",
            mods = "CTRL|SHIFT|ALT",
            action = act.SendString("\u{E023}"),
          },
          {
            key = "}",
            mods = "CTRL|SHIFT|ALT",
            action = act.SendString("\u{E024}"),
          },
          {
            key = "Enter",
            mods = "SHIFT",
            action = act.SendString("\u{001b}[13;2u"),
          },
          {
            key = "c",
            mods = "CTRL|SHIFT",
            action = act.CopyTo("Clipboard"),
          },
          {
            key = "v",
            mods = "CTRL|SHIFT",
            action = act.PasteFrom("Clipboard"),
          },
          {
            key = "+",
            mods = "CTRL|SHIFT",
            action = act.IncreaseFontSize,
          },
          {
            key = "_",
            mods = "CTRL|SHIFT",
            action = act.DecreaseFontSize,
          },
          {
            key = ")",
            mods = "CTRL|SHIFT",
            action = act.ResetFontSize,
          },
          {
            key = "PageUp",
            mods = "SHIFT",
            action = act.ScrollByPage(-1),
          },
          {
            key = "PageDown",
            mods = "SHIFT",
            action = act.ScrollByPage(1),
          },
          {
            key = "p",
            mods = "CTRL|SHIFT",
            action = act.ActivateCommandPalette,
          },
          {
            key = "d",
            mods = "CTRL|SHIFT",
            action = act.ShowDebugOverlay,
          },
          {
            key = "f",
            mods = "CTRL|SHIFT",
            action = act.Search({ CaseSensitiveString = "" }),
          },
          {
            key = "Space",
            mods = "CTRL|SHIFT",
            action = act.QuickSelect,
          },
        }

        return config
      '';
    };
  };
}

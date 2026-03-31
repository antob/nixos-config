{ config, lib, ... }:

with lib;
let
  cfg = config.antob.tools.wezterm;
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

        -- Plugin imports
        -- Run the command `wezterm.plugin.update_all()` from the debug overlay to update all local plugins.
        local ws_mgr = wezterm.plugin.require("https://github.com/antob/wezterm-workspace-manager")

        -- General settings
        config.color_scheme = "Tokyo Night"
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

        -- Multiplexing
        config.unix_domains = {
          {
            name = "unix",
          },
        }

        -- This causes `wezterm` to act as though it was started as
        -- `wezterm connect unix` by default, connecting to the unix
        -- domain on startup.
        -- If you prefer to connect manually, leave out this line.
        config.default_gui_startup_args = { "connect", "unix" }

        -- Tab bar settings
        config.enable_tab_bar = true
        config.use_fancy_tab_bar = false
        config.tab_bar_at_bottom = true
        config.show_new_tab_button_in_tab_bar = false
        config.hide_tab_bar_if_only_one_tab = false
        config.tab_max_width = 64

        -- Leader key
        config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

        -- Workspace settings
        wezterm.on("update-right-status", function(window, _)
          window:set_right_status(window:active_workspace())
        end)

        -- Key bindings
        config.disable_default_key_bindings = true
        config.keys = {
          {
            key = "n",
            mods = "CTRL|SHIFT",
            action = act.SpawnWindow,
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
            key = "t",
            mods = "CTRL|SHIFT",
            action = act.SpawnTab("DefaultDomain"),
          },
          {
            key = "w",
            mods = "CTRL|SHIFT",
            action = act.CloseCurrentTab({ confirm = true }),
          },
          {
            key = "}",
            mods = "CTRL|SHIFT",
            action = act.ActivateTabRelative(1),
          },
          {
            key = "{",
            mods = "CTRL|SHIFT",
            action = act.ActivateTabRelative(-1),
          },
          {
            key = "PageUp",
            mods = "CTRL|SHIFT",
            action = act.MoveTabRelative(-1),
          },
          {
            key = "PageDown",
            mods = "CTRL|SHIFT",
            action = act.MoveTabRelative(1),
          },
          {
            key = "m",
            mods = "CTRL|SHIFT",
            action = act.TogglePaneZoomState,
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
            key = "r",
            mods = "CTRL|SHIFT",
            action = act.ReloadConfiguration,
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
            key = "x",
            mods = "CTRL|SHIFT",
            action = act.ActivateCopyMode,
          },
          {
            key = "Space",
            mods = "CTRL|SHIFT",
            action = act.QuickSelect,
          },
          {
            key = '"',
            mods = "CTRL|SHIFT",
            action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
          },
          {
            key = ":",
            mods = "CTRL|SHIFT",
            action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
          },
          {
            key = "LeftArrow",
            mods = "CTRL|SHIFT|ALT",
            action = act.AdjustPaneSize({ "Left", 5 }),
          },
          {
            key = "RightArrow",
            mods = "CTRL|SHIFT|ALT",
            action = act.AdjustPaneSize({ "Right", 5 }),
          },
          {
            key = "UpArrow",
            mods = "CTRL|SHIFT|ALT",
            action = act.AdjustPaneSize({ "Up", 5 }),
          },
          {
            key = "DownArrow",
            mods = "CTRL|SHIFT|ALT",
            action = act.AdjustPaneSize({ "Down", 5 }),
          },
          {
            key = "LeftArrow",
            mods = "CTRL|SHIFT",
            action = act.ActivatePaneDirection("Prev"),
          },
          {
            key = "RightArrow",
            mods = "CTRL|SHIFT",
            action = act.ActivatePaneDirection("Next"),
          },
          {
            key = "r",
            mods = "CTRL|SHIFT",
            action = act.RotatePanes("Clockwise"),
          },
          {
            key = "a",
            mods = "LEADER",
            action = act.SendKey({
              mods = "CTRL",
              key = "a",
            }),
          },
          {
            key = "a",
            mods = "LEADER|CTRL",
            action = act.SendKey({
              mods = "CTRL",
              key = "a",
            }),
          },

          -- Plugin keybindings
          {
            key = "s",
            mods = "LEADER",
            action = ws_mgr.apply_workspace(),
          },
          {
            key = "s",
            mods = "LEADER|CTRL",
            action = ws_mgr.apply_workspace(),
          },
          {
            key = "s",
            mods = "LEADER|SHIFT",
            action = ws_mgr.save_workspace(),
          },
          {
            key = "d",
            mods = "LEADER|SHIFT",
            action = ws_mgr.delete_workspace(),
          },
          -- Rename current workspace
          {
            key = "$",
            mods = "CTRL|SHIFT",
            action = act.PromptInputLine({
              description = "Enter new workspace name",
              action = wezterm.action_callback(function(window, pane, line)
                if line then
                  wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
                end
              end),
            }),
          },
          -- Prompt for a name to use for a new workspace and switch to it.
          {
            key = "n",
            mods = "LEADER|SHIFT",
            action = act.PromptInputLine({
              description = wezterm.format({
                { Attribute = { Intensity = "Bold" } },
                { Foreground = { AnsiColor = "Fuchsia" } },
                { Text = "Enter name for new workspace" },
              }),
              action = wezterm.action_callback(function(window, pane, line)
                if line then
                  window:perform_action(
                    act.SwitchToWorkspace({
                      name = line,
                    }),
                    pane
                  )
                end
              end),
            }),
          },
        }

        return config
      '';
    };
  };
}

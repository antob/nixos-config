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

        -- Plugin imports
        -- Run the command `wezterm.plugin.update_all()` from the debug overlay to update all local plugins.
        -- local ws_mgr = wezterm.plugin.require("https://github.com/antob/wezterm-workspace-manager")

        -- Customize the Tokyo Night theme
        local custom_theme = wezterm.color.get_builtin_schemes()["Tokyo Night"]
        -- custom_theme.selection_bg = "#${colors.base04}"
        custom_theme.selection_fg = "none"
        custom_theme.selection_bg = "rgba(90% 90% 90% 25%)"
        custom_theme.split = "#${colors.base0C}"
        config.inactive_pane_hsb = {
          saturation = 0.8,
          brightness = 0.65,
        }

        -- Helper functions
        function basename(s)
          return string.gsub(s, "(.*[/\\])(.*)", "%2")
        end
        function projects(rel_dir)
          return wezterm.home_dir .. "/Projects/" .. rel_dir
        end

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

        function last_path_segment(path)
          return path:match("([^/]+)$")
        end

        function spawn_window(cwd, title, domain)
          title = title or last_path_segment(cwd)
          local tab, pane, window = wezterm.mux.spawn_window({
            workspace = title,
            cwd = cwd,
          })
          tab:set_title(title)

          return window, tab, pane
        end

        function spawn_or_setup_tab(window_or_tab, cwd, title)
          title = title or last_path_segment(cwd)
          local tab = nil
          local pane = nil

          if type(window_or_tab.spawn_tab) == "function" then
            tab, pane, _ = window_or_tab:spawn_tab({
              cwd = cwd,
            })
          else
            tab, pane = window_or_tab, window_or_tab:active_pane()
          end

          tab:set_title(title)

          return tab, pane
        end

        function two_splits_pane(pane)
          pane:split({ direction = "Left", size = 0.5 })
        end

        function three_splits_pane(pane)
          pane:split({ direction = "Bottom", size = 0.5 })
          pane:split({ direction = "Left", size = 0.33, top_level = true })
        end

        function two_splits_tab(window_or_tab, cwd, title)
          local tab, pane = spawn_or_setup_tab(window_or_tab, cwd, title)
          two_splits_pane(pane)

          return tab, pane
        end

        function three_splits_tab(window_or_tab, cwd, title)
          local tab, pane = spawn_or_setup_tab(window_or_tab, cwd, title)
          three_splits_pane(pane)

          return tab, pane
        end

        -- Default workspaces
        wezterm.on("gui-startup", function()
          -- nixos-config
          local window, tab, pane = spawn_window(projects("nixos-config"))
          two_splits_pane(pane)

          -- trafikportalen
          local window, tab, pane = spawn_window(projects("hl-design/trafikportal"))
          three_splits_pane(pane)

          -- vesselcare
          local cwd = projects("obit/VesselCare")
          local window, tab, pane = spawn_window(cwd .. "/VesselCare-webapp", "VesselCare")
          three_splits_tab(tab, cwd, "webapp")
          three_splits_tab(window, cwd .. "/AnchorPoint")
          three_splits_tab(window, cwd .. "/ProcessingPipeline")
          three_splits_tab(window, cwd .. "/UserAccessManagement")
          two_splits_tab(window, cwd .. "/internal-python-library", "apilib")
          tab:activate()

          -- default
          spawn_window(wezterm.home_dir, "default")

          wezterm.mux.set_active_workspace("default")
        end)

        -- Key bindings
        config.disable_default_key_bindings = true
        config.keys = {
          {
            key = "q",
            mods = "CMD|SHIFT",
            action = act.QuitApplication,
          },
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
            action = act.SpawnTab("CurrentPaneDomain"),
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
            key = "<",
            mods = "CTRL|SHIFT",
            action = act.PromptInputLine({
              description = "Rename Tab",
              action = wezterm.action_callback(function(window, pane, line)
                if line then
                  window:active_tab():set_title(line)
                end
              end),
            }),
          },
          {
            key = "s",
            mods = "LEADER",
            action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
          },
          {
            key = "s",
            mods = "LEADER|CTRL",
            action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
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
            key = "s",
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

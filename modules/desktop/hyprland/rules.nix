{
  flake.modules.homeManager.hyprland =
    { lib, ... }:
    {
      # Lua fragment 2 of 4: workspace, window and layer rules.
      wayland.windowManager.hyprland.extraConfig = lib.mkOrder 200 /* lua */ ''
        ----------------------------------------------------------------------------
        -- Workspace rules
        -- https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
        ----------------------------------------------------------------------------

        -- Persistent workspaces
        for i = 1, 5 do
          hl.workspace_rule({ workspace = tostring(i), persistent = true })
        end

        pcall(require, "workspaces")

        ----------------------------------------------------------------------------
        -- Window rules
        -- https://wiki.hypr.land/Configuring/Basics/Window-Rules/
        ----------------------------------------------------------------------------

        hl.window_rule({
          name = "suppress-maximize-events",
          match = { class = ".*" },
          suppress_event = "maximize",
        })

        -- Just dash of opacity by default
        hl.window_rule({
          name = "default-opacity",
          match = { class = ".*" },
          opacity = "0.95 0.95",
        })

        -- No transparency on specific windows
        hl.window_rule({
          name = "opaque-media",
          match = { class = "^(zoom|vlc|mpv|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer|X64)$" },
          opacity = "1 1",
        })
        hl.window_rule({
          name = "opaque-apps",
          match = { class = "^(firefox|Alacritty|org.gnome.Nautilus)$" },
          opacity = "1 1",
        })

        hl.window_rule({
          name = "opaque-games",
          match = { class = "^(gamescope|steam_app_.*)$" },
          opacity = "1 1",
        })

        -- Scroll faster in the terminal
        hl.window_rule({
          name = "terminal-scroll-touchpad",
          match = { class = "(Alacritty|kitty)" },
          scroll_touchpad = 1.5,
        })

        -- Floating windows, selected by tag
        hl.window_rule({
          name = "floating-window",
          match = { tag = "floating-window" },
          float = true,
          center = true,
          size = { 800, 600 },
        })
        hl.window_rule({
          name = "floating-window-lg",
          match = { tag = "floating-window-lg" },
          float = true,
          center = true,
          size = { 1100, 700 },
        })

        hl.window_rule({
          name = "tag-floating-window",
          match = { class = "(Wiremix|org.gnome.NautilusPreviewer|com.gabm.satty|About|TUI.float)" },
          tag = "+floating-window",
        })
        hl.window_rule({
          name = "tag-floating-share-picker",
          match = { title = "^Select what to share$" },
          tag = "+floating-window",
        })
        hl.window_rule({
          name = "tag-floating-dialogs",
          match = {
            class = "(xdg-desktop-portal-gtk|DesktopEditors|org.gnome.Nautilus)",
            title = "^(Open.*Files?|Open Folder|Save.*Files?|Save.*As|Save|All Files)",
          },
          tag = "+floating-window",
        })
        -- Steam's main window is titled "Steam"; Properties, Friends, Settings etc. are not
        hl.window_rule({
          name = "tag-floating-steam-dialogs",
          match = { class = "^steam$", title = "negative:^(Steam)?$" },
          tag = "+floating-window-lg",
        })
        hl.window_rule({
          name = "tag-floating-obsidian-settings",
          match = { class = "^md.obsidian.Obsidian$", title = "^Settings - .*Obsidian.*$" },
          tag = "+floating-window-lg",
        })
        hl.window_rule({
          name = "tag-floating-window-lg",
          match = { class = "(TUI.float.lg|nwg-displays|X64)" },
          tag = "+floating-window-lg",
        })

        -- Noctalia settings
        hl.window_rule({
          name = "noctalia-settings",
          match = { class = "dev.noctalia.Noctalia" },
          float = true,
          size = { "1080", "monitor_h*0.75" },
        })

        -- fs-uae
        hl.window_rule({
          name = "fs-uae",
          match = { class = "fs-uae" },
          float = true,
          size = { 960, 768 },
          opacity = "1 1",
        })

        -- Picture-in-picture: float, pin and keep in the top-right corner
        hl.window_rule({
          name = "pip",
          match = { title = "^(Picture.?in.?[Pp]icture)$" },
          float = true,
          pin = true,
          size = { 600, 338 },
          keep_aspect_ratio = true,
          border_size = 0,
          opacity = "1 1",
          move = { "(monitor_w-window_w-40)", "(monitor_h*0.04)" },
        })

        -- Keep password managers out of screen shares
        hl.window_rule({ name = "no-share-bitwarden", match = { class = "^([bB]itwarden)$" }, no_screen_share = true })

        -- Hide the browsers' "sharing your screen" indicator windows
        hl.window_rule({ name = "hide-share-indicator", match = { title = "(.*is sharing.*|.*Sharing Indicator)" }, workspace = "special silent" })

        -- Don't let Telegram steal focus on new messages
        hl.window_rule({ name = "telegram-no-focus-steal", match = { class = "org.telegram.desktop" }, focus_on_activate = false })

        -- No idle lock while games are fullscreen
        hl.window_rule({ name = "games-idle-inhibit", match = { class = "^(steam|steam_app_.*|gamescope)$" }, idle_inhibit = "fullscreen" })

        -- Stop XWayland drag-and-drop ghost windows from taking focus
        hl.window_rule({
          name = "xwayland-drag-fix",
          match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
          no_focus = true,
        })

        -- Fullscreen screensaver
        hl.window_rule({ name = "fullscreen-screensaver", match = { class = "Screensaver" }, fullscreen = true })

        -- Do not animate fullscreen windows
        hl.window_rule({ name = "no-anim-fullscreen", match = { fullscreen = true }, no_anim = true })

        -- Float and center the Bitwarden browser extension popup. Firefox maps every new
        -- window as "Mozilla Firefox" and sets the real title ~50ms later, so park them on a
        -- hidden workspace until then and bring them back tiled, or floating if Bitwarden.
        local firefoxPendingWs = "special:firefox-pending"
        hl.window_rule({
          name = "firefox-untitled",
          match = { class = "^firefox$", initial_title = "^Mozilla Firefox$" },
          workspace = firefoxPendingWs .. " silent",
        })

        local function floatBitwarden(w)
          hl.dispatch(hl.dsp.window.set_prop({ prop = "no_anim", value = "on", window = w }))
          hl.dispatch(hl.dsp.window.set_prop({ prop = "no_screen_share", value = "on", window = w }))
          hl.dispatch(hl.dsp.window.float({ action = "enable", window = w }))
          hl.dispatch(hl.dsp.window.resize({ x = 500, y = 800, window = w }))
        end

        -- stable_id -> workspace the window was opened from
        local firefoxPending = {}
        local function unpark(w, isBitwarden)
          local target = firefoxPending[w.stable_id]
          firefoxPending[w.stable_id] = nil
          if isBitwarden then floatBitwarden(w) end
          hl.dispatch(hl.dsp.window.move({ workspace = target, follow = false, window = w }))
          if isBitwarden then hl.dispatch(hl.dsp.window.center({ window = w })) end
          hl.dispatch(hl.dsp.focus({ window = w }))
        end

        hl.on("window.open", function(w)
          if not (w.class == "firefox" and w.initial_title == "Mozilla Firefox") then return end
          local ws = hl.get_active_special_workspace() or hl.get_active_workspace()
          local id = w.stable_id
          firefoxPending[id] = ws and (ws.special and ws.name or ws.id) or "e+0"
          -- Pages without a title (e.g. an HTTP auth prompt) never send a title change
          hl.timer(function()
            if not firefoxPending[id] then return end
            for _, win in ipairs(hl.get_windows({ class = "firefox" })) do
              if win.stable_id == id then unpark(win, false) end
            end
            firefoxPending[id] = nil
          end, { timeout = 1000, type = "oneshot" })
        end)

        hl.on("window.title", function(w)
          if not w.title then return end
          if firefoxPending[w.stable_id] then
            unpark(w, w.title:find("Extension: (Bitwarden Password Manager)", 1, true) ~= nil)
          elseif w.title:find("(Bitwarden Password Manager) - Bitwarden", 1, true) then
            floatBitwarden(w)
            hl.dispatch(hl.dsp.window.center({ window = w }))
          end
        end)

        ----------------------------------------------------------------------------
        -- Layer rules
        ----------------------------------------------------------------------------

        -- Remove 1px border around hyprshot screenshots
        hl.layer_rule({ name = "no-anim-selection", match = { namespace = "selection" }, no_anim = true })

        -- No animations on rofi menues
        hl.layer_rule({ name = "no-anim-rofi", match = { namespace = "rofi" }, no_anim = true })

        -- Noctalia shell surfaces
        hl.layer_rule({
          name = "noctalia",
          match = {
            namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
          },
          no_anim = true,
          ignore_alpha = 0.5,
          blur = true,
          blur_popups = true,
        })
      '';
    };
}

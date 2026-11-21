{
  flake.modules.homeManager.hyprland =
    { osConfig, lib, ... }:
    let
      inherit (osConfig.lib.stylix) colors;
    in
    {
      # Lua fragment 1 of 4: monitors, environment, look and feel, input, misc.
      wayland.windowManager.hyprland.extraConfig = lib.mkOrder 100 /* lua */ ''
        ----------------------------------------------------------------------------
        -- Monitors
        -- https://wiki.hypr.land/Configuring/Basics/Monitors/
        ----------------------------------------------------------------------------

        -- Default
        hl.monitor({ output = "", mode = "preferred", position = "auto-center-up", scale = "auto" })

        -- Set by nwg-displays. `source = ~/.config/hypr/monitors.conf` can't load a
        -- hyprlang file from Lua; nwg-displays (>= 0.4.4) also writes a Lua version
        -- next to it (monitors.lua). The config dir is on package.path, and pcall
        -- keeps a missing file from being an error.
        -- nwg-displays always writes a per-monitor vrr (0 unless toggled there); drop it so misc.vrr applies.
        local monitor = hl.monitor
        hl.monitor = function(rule)
          rule.vrr = nil
          return monitor(rule)
        end
        pcall(require, "monitors")
        hl.monitor = monitor

        ----------------------------------------------------------------------------
        -- Environment variables
        -- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
        ----------------------------------------------------------------------------

        hl.env("GDK_SCALE", "1")

        -- Cursor size
        hl.env("XCURSOR_SIZE", "16")
        hl.env("HYPRCURSOR_SIZE", "16")

        -- Force all apps to use Wayland
        hl.env("GDK_BACKEND", "wayland,x11,*")
        hl.env("QT_QPA_PLATFORM", "wayland;xcb")
        hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
        hl.env("SDL_VIDEODRIVER", "wayland")
        hl.env("MOZ_ENABLE_WAYLAND", "1")
        hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
        hl.env("OZONE_PLATFORM", "wayland")

        ----------------------------------------------------------------------------
        -- Autostart
        -- https://wiki.hypr.land/Configuring/Basics/Autostart/
        ----------------------------------------------------------------------------

        hl.on("hyprland.start", function()
          hl.exec_cmd("noctalia")
        end)

        ----------------------------------------------------------------------------
        -- Look and feel
        -- https://wiki.hypr.land/Configuring/Basics/Variables/
        ----------------------------------------------------------------------------

        hl.config({
          general = {
            gaps_in = 5,
            gaps_out = 10,

            border_size = 3,

            -- Resize floating windows by dragging their borders
            resize_on_border = true,
            extend_border_grab_area = 8,
            hover_icon_on_border = true,

            -- Async page flips fail on amdgpu here ("failed to commit: Invalid argument") and freeze the game.
            allow_tearing = false,

            layout = "scrolling",
          },

          decoration = {
            rounding = 4,
            rounding_power = 2,

            shadow = {
              enabled = true,
              range = 4, -- was 2 in the old modular config
              render_power = 3,
              color = "rgba(${colors.base00}ee)",
            },

            blur = {
              enabled = true,
              size = 3,
              passes = 2, -- was 1 in the old modular config
              vibrancy = 0.1696,
            },
          },

          animations = {
            enabled = true,
          },
        })

        ----------------------------------------------------------------------------
        -- Animations
        -- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
        ----------------------------------------------------------------------------

        hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
        hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
        hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
        hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
        hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

        hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
        hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
        local slideSpeed = 4.79 -- deciseconds; shared by window moves and workspace slides
        hl.animation({ leaf = "windows", enabled = true, speed = slideSpeed, bezier = "easeOutQuint" })
        local windowsMoveAnim = { leaf = "windowsMove", enabled = true, speed = slideSpeed, bezier = "easeOutQuint" }
        hl.animation(windowsMoveAnim)
        hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
        hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
        hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
        hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
        hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
        -- The monocle layout hides inactive windows by fading their alpha with
        -- fadeSwitch, so cycling (Mod + Left/Right) cross-fades both windows and
        -- the background shows through. Make that switch instant. This also makes
        -- active/inactive opacity changes and group tab switches instant.
        hl.animation({ leaf = "fadeSwitch", enabled = false })
        hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
        hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
        hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
        hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
        hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
        -- Slide workspaces vertically, with the same speed and curve as moving between
        -- columns in the scrolling layout (windowsMove).
        -- Higher workspace numbers slide in from below.
        hl.animation({ leaf = "workspaces", enabled = true, speed = slideSpeed, bezier = "easeOutQuint", style = "slidevert" })
        local specialWorkspaceAnim = { leaf = "specialWorkspace", enabled = true, speed = slideSpeed, bezier = "easeOutQuint", style = "slidevert" }
        hl.animation(specialWorkspaceAnim)

        ----------------------------------------------------------------------------
        -- Layouts and groups
        -- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
        -- https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
        -- https://wiki.hypr.land/Configuring/Basics/Variables/#group
        ----------------------------------------------------------------------------

        hl.config({
          scrolling = {
            follow_focus = true,
            focus_fit_method = 0, -- 0 = center, 1 = fit
            wrap_focus = false,
            column_width = 1.0,
            fullscreen_on_one_column = false,
          },

          master = {
            new_status = "master",
            new_on_top = true,
            mfact = 0.50,
          },

          group = {
            focus_removed_window = true,

            groupbar = {
              enabled = false,
            },
          },
        })

        ----------------------------------------------------------------------------
        -- Input
        -- https://wiki.hypr.land/Configuring/Basics/Variables/#input
        ----------------------------------------------------------------------------

        hl.config({
          input = {
            kb_layout = "se",
            kb_variant = "us",
            kb_model = "",
            kb_options = "caps:ctrl_modifier", -- compose:caps
            -- kb_options = "compose:caps",
            kb_rules = "",

            repeat_rate = 40,
            repeat_delay = 200,
            follow_mouse = 1,
            sensitivity = 0,
            focus_on_close = 2,
            numlock_by_default = true,

            touchpad = {
              natural_scroll = true,
              scroll_factor = 0.4,
              -- Two-finger click is right-click
              clickfinger_behavior = true,
            },
          },

          cursor = {
            hide_on_key_press = true,
            inactive_timeout = 10,
          },

          binds = {
            movefocus_cycles_fullscreen = true,
            allow_workspace_cycles = true,
            workspace_back_and_forth = true,
          },
        })

        ----------------------------------------------------------------------------
        -- Misc
        -- https://wiki.hypr.land/Configuring/Basics/Variables/#misc
        ----------------------------------------------------------------------------

        hl.config({
          misc = {
            disable_hyprland_logo = true,
            disable_splash_rendering = true,
            focus_on_activate = true,
            vrr = 2, -- fullscreen only
            -- Let a restarted Noctalia take the lock back if it crashed while locked
            allow_session_lock_restore = true,
            -- Fewer false "app not responding" dialogs
            anr_missed_pings = 3,
            key_press_enables_dpms = true,
            mouse_move_enables_dpms = true,
          },

          xwayland = {
            force_zero_scaling = true,
          },

          render = {
            -- HDR only for fullscreen apps that request it; desktop stays SDR
            cm_auto_hdr = 1,
          },

          ecosystem = {
            no_update_news = true,
            no_donation_nag = true,
          },

          -- Disable checks for fractional scaling
          debug = {
            disable_scale_checks = true,
          },
        })
      '';
    };
}

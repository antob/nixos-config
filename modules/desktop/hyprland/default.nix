{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.hyprland;
  gtkCfg = config.antob.desktop.addons.gtk;
  inherit (config.antob.color-scheme) colors;

  dm-firefox-profile = getExe (
    pkgs.callPackage ../scripts/dm-firefox-profile.nix { inherit config; }
  );
  dm-herdr-session = getExe (pkgs.callPackage ../scripts/dm-herdr-session.nix { inherit config; });
  dm-keybindings = getExe (pkgs.callPackage ./scripts/dm-keybindings.nix { });
  dm-vpn =
    if config.antob.services.networkd-vpn.enable then
      getExe (pkgs.callPackage ../scripts/dm-networkd-vpn.nix { inherit config; })
    else
      getExe (pkgs.callPackage ../scripts/dm-nm-vpn.nix { });
in
{
  options.antob.desktop.hyprland = with types; {
    enable = mkEnableOption "Enable Hyprland.";
  };

  config = mkIf cfg.enable {
    programs = {
      hyprland = {
        enable = true;
        withUWSM = true;
      };

      dconf.enable = true;
    };

    # xdg-desktop-portal-gnome FileChooser call depends on Nautilus
    services.dbus.packages = [ pkgs.nautilus ];

    antob = {
      desktop.addons = {
        gtk = enabled;
        nautilus = enabled;
        noctalia = enabled;
        rofi = {
          enable = true;
          launchPrefix = "uwsm app -- ";
        };
      };

      home.extraOptions = {
        dconf.settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            accent-color = "teal";
            gtk-theme = gtkCfg.theme.name;
            cursor-theme = gtkCfg.cursor.name;
            cursor-size = gtkCfg.cursor.size;
          };
        };

        services.hyprpolkitagent.enable = true;

        wayland.windowManager.hyprland = {
          enable = true;
          configType = "lua";
          systemd.enable = false; # Conflicts with UWSM
          xwayland.enable = true; # Default

          extraConfig = /* lua */ ''
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
            pcall(require, "monitors")

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
            hl.env("QT_STYLE_OVERRIDE", "kvantum")
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

                border_size = 2,

                -- https://wiki.hypr.land/Configuring/Basics/Variables/#variable-types for info about colors
                col = {
                  active_border = "rgba(${colors.base0C}ff)",
                  inactive_border = "rgba(${colors.base12}aa)",
                },

                -- Set to true enable resizing windows by clicking and dragging on borders and gaps
                resize_on_border = false,

                -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
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
                  color = 0xee1a1a1a,
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
            hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
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
            -- columns in the scrolling layout (windowsMove, inherited from windows).
            -- Higher workspace numbers slide in from below.
            hl.animation({ leaf = "workspaces", enabled = true, speed = 4.79, bezier = "easeOutQuint", style = "slidevert" })

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
              },

              master = {
                new_status = "master",
                new_on_top = true,
                mfact = 0.50,
              },

              group = {
                focus_removed_window = true,

                col = {
                  border_active = "rgba(${colors.base0D}ff)",
                  border_inactive = "rgba(${colors.base12}aa)",
                },

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

                touchpad = {
                  natural_scroll = true,
                  scroll_factor = 0.4,
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
              },

              xwayland = {
                force_zero_scaling = true,
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
              opacity = "1.0 0.95",
            })

            -- No transparency on specific windows
            hl.window_rule({
              name = "opaque-media",
              match = { class = "^(zoom|vlc|mpv|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer|X64)$" },
              opacity = "1 1",
            })
            hl.window_rule({
              name = "opaque-apps",
              match = { class = "^(firefox|Alacritty|kitty)$" },
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
              name = "tag-floating-dialogs",
              match = {
                class = "(xdg-desktop-portal-gtk|DesktopEditors|org.gnome.Nautilus)",
                title = "^(Open.*Files?|Open Folder|Save.*Files?|Save.*As|Save|All Files)",
              },
              tag = "+floating-window",
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
              size = { 1080, 920 },
            })

            -- fs-uae
            hl.window_rule({
              name = "fs-uae",
              match = { class = "fs-uae" },
              float = true,
              size = { 960, 768 },
              opacity = "1 1",
            })

            -- Fullscreen screensaver
            hl.window_rule({ name = "fullscreen-screensaver", match = { class = "Screensaver" }, fullscreen = true })

            -- Do not animate fullscreen windows
            hl.window_rule({ name = "no-anim-fullscreen", match = { fullscreen = true }, no_anim = true })

            -- Float and resize the Bitwarden browser extension popup. Its title is only
            -- set after the window opens, so a static window rule can't match it.
            hl.on("window.title", function(w)
              if w.title and w.title:find("(Bitwarden Password Manager) - Bitwarden", 1, true) then
                hl.dispatch(hl.dsp.window.set_prop({ prop = "no_anim", value = "on", window = w }))
                hl.dispatch(hl.dsp.window.float({ action = "enable", window = w }))
                hl.dispatch(hl.dsp.window.resize({ x = 500, y = 800, window = w }))
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

            ----------------------------------------------------------------------------
            -- Keybindings
            -- https://wiki.hypr.land/Configuring/Basics/Binds/
            -- Kept in line with the Niri bindings (modules/desktop/niri/default.nix).
            -- Niri's columns map to the scrolling layout (`hl.dsp.layout(...)`).
            ----------------------------------------------------------------------------

            local mainMod = "SUPER"
            local ipc = "noctalia msg "

            local terminal = "uwsm app -- ${pkgs.kitty}/bin/kitty"
            local tmuxTerminal = "uwsm app -- ${pkgs.kitty}/bin/kitty tmux-attach-unused"
            local tuiTerminal = "uwsm app -- ${pkgs.alacritty}/bin/alacritty"
            local browser = "uwsm app -- firefox"
            -- Unused
            -- local chromium = "uwsm app -- chromium --app="

            -- Pick the dispatcher for the active workspace's tiled layout (scrolling,
            -- master, monocle, dwindle), falling back to `default`.
            local function perLayout(dispatchers)
              return function()
                local ws = hl.get_active_workspace()
                local d = dispatchers[ws and ws.tiled_layout] or dispatchers.default
                if d then
                  hl.dispatch(d)
                end
              end
            end

            -- Workspaces 1 to maxWorkspace are reachable with Mod + [number]
            local maxWorkspace = 9

            -- Run the dispatcher only when there is a workspace above the active one.
            local function ifWorkspaceAbove(dispatcher)
              return function()
                local ws = hl.get_active_workspace()
                if ws and ws.id > 1 then
                  hl.dispatch(dispatcher)
                end
              end
            end

            -- Run the dispatcher only when there is a workspace below the active one.
            local function ifWorkspaceBelow(dispatcher)
              return function()
                local ws = hl.get_active_workspace()
                if ws and ws.id < maxWorkspace then
                  hl.dispatch(dispatcher)
                end
              end
            end

            -- Run several dispatchers from one bind.
            local function dispatchAll(...)
              local dispatchers = { ... }
              return function()
                for _, d in ipairs(dispatchers) do
                  hl.dispatch(d)
                end
              end
            end

            -- Noctalia ------------------------------------------------------------------

            hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"), { description = "Launcher" })
            hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"), { description = "Control center" })
            hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(ipc .. "settings-toggle"), { description = "Settings" })
            hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(ipc .. "panel-open control-center bluetooth"), { description = "Bluetooth" })
            hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(ipc .. "panel-open session"), { description = "System menu" })
            hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(ipc .. "session lock"), { description = "Lock screen" })
            hl.bind(mainMod .. " + U", hl.dsp.exec_cmd(ipc .. "caffeine-toggle"), { description = "Toggle locking on idle" })
            hl.bind("ALT + Tab", hl.dsp.exec_cmd(ipc .. "window-switcher hold"), { description = "Window switcher" })

            -- Media keys ------------------------------------------------------------------

            hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. "volume-up"), { repeating = true, locked = true, description = "Volume up" })
            hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. "volume-down"), { repeating = true, locked = true, description = "Volume down" })
            hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. "volume-mute"), { locked = true, description = "Mute" })
            hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(ipc .. "mic-mute"), { locked = true, description = "Mute microphone" })
            hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. "brightness-up"), { repeating = true, locked = true, description = "Brightness up" })
            hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness-down"), { repeating = true, locked = true, description = "Brightness down" })

            -- Apps ------------------------------------------------------------------------

            hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(tmuxTerminal), { description = "Terminal (tmux)" })
            hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(terminal), { description = "Terminal" })
            hl.bind(mainMod .. " + ALT + Return", hl.dsp.exec_cmd("${dm-herdr-session}"), { description = "Herdr" })
            hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("uwsm app -- nautilus --new-window"), { description = "File manager" })
            hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(browser), { description = "Web browser" })
            hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("${dm-firefox-profile}"), { description = "Select Firefox profile" })
            hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(tuiTerminal .. " --class=TUI.float.lg -e ${pkgs.impala}/bin/impala"), { description = "WIFI" })
            hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(tuiTerminal .. " --class=TUI.float.lg -e ${getExe pkgs.bottom}"), { description = "Activity" })
            hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("uwsm app -- ${getExe pkgs.nwg-displays}"), { description = "Displays" })

            -- Menus -----------------------------------------------------------------------

            hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("${pkgs.rofi}/bin/rofi -show drun -show-icons"), { description = "App launcher" })
            hl.bind(mainMod .. " + CTRL + E", hl.dsp.exec_cmd("rofimoji --prompt Emojis --action copy"), { description = "Emoji selector" })
            hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("${dm-vpn}"), { description = "Show VPN menu" })
            hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("${dm-keybindings}"), { description = "Show key bindings" })

            -- Utilities -------------------------------------------------------------------

            -- Screenshots
            hl.bind("Print", hl.dsp.exec_cmd(ipc .. "screenshot-region"), { description = "Screenshot of region" })

            -- Layouts ---------------------------------------------------------------------

            -- `hyprctl keyword` doesn't work with the Lua config, so set the option directly.
            hl.bind(mainMod .. " + ALT + M", function() hl.config({ general = { layout = "master" } }) end, { description = "Switch to master layout" })
            hl.bind(mainMod .. " + ALT + S", function() hl.config({ general = { layout = "scrolling" } }) end, { description = "Switch to scrolling layout" })
            hl.bind(mainMod .. " + ALT + O", function() hl.config({ general = { layout = "monocle" } }) end, { description = "Switch to monocle layout" })

            -- Swap active window with master
            hl.bind(mainMod .. " + BackSpace", perLayout({ master = hl.dsp.layout("swapwithmaster auto") }), { description = "Swap window with master" })

            -- Windows ---------------------------------------------------------------------

            hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close active window" })
            hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
            hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(), { description = "Full screen" })
            hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "Maximize window" })

            -- Switch focus between floating and tiled windows
            hl.bind(mainMod .. " + SHIFT + V", function()
              local w = hl.get_active_window()
              hl.dispatch(hl.dsp.focus({ window = (w and w.floating) and "tiled" or "floating" }))
            end, { description = "Switch focus between floating and tiling" })

            -- Move/resize windows with mainMod + LMB/RMB and dragging
            hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window" })
            hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

            -- Focus -----------------------------------------------------------------------

            -- Like Niri's focus-window-or-workspace-up/down: move within the column and
            -- go to the previous/next workspace at the top/bottom. general:no_focus_fallback
            -- is enabled for the move so the layout doesn't wrap within the column;
            local function focusWindowOrWorkspace(dir, fallback)
              return function()
                hl.config({ general = { no_focus_fallback = true } })
                local result = hl.dispatch(hl.dsp.layout("focus " .. dir))
                hl.config({ general = { no_focus_fallback = false } })
                if not (result and result.ok) then
                  hl.dispatch(fallback)
                end
              end
            end

            -- Monocle has no windows above/below, so switch workspace there.
            hl.bind(mainMod .. " + up", perLayout({
              scrolling = focusWindowOrWorkspace("u", ifWorkspaceAbove(hl.dsp.focus({ workspace = "r-1" }))),
              monocle = ifWorkspaceAbove(hl.dsp.focus({ workspace = "r-1" })),
              default = hl.dsp.focus({ direction = "up" }),
            }), { description = "Focus window or workspace up" })
            hl.bind(mainMod .. " + down", perLayout({
              scrolling = focusWindowOrWorkspace("d", ifWorkspaceBelow(hl.dsp.focus({ workspace = "r+1" }))),
              monocle = ifWorkspaceBelow(hl.dsp.focus({ workspace = "r+1" })),
              default = hl.dsp.focus({ direction = "down" }),
            }), { description = "Focus window or workspace down" })

            hl.bind(mainMod .. " + left", perLayout({
              scrolling = hl.dsp.layout("focus l"),
              monocle = hl.dsp.layout("cycleprev"),
              default = hl.dsp.focus({ direction = "left" }),
            }), { description = "Move focus left" })
            hl.bind(mainMod .. " + right", perLayout({
              scrolling = hl.dsp.layout("focus r"),
              monocle = hl.dsp.layout("cyclenext"),
              default = hl.dsp.focus({ direction = "right" }),
            }), { description = "Move focus right" })

            -- Focus next/previous column, wrapping around like Niri's
            -- focus-column-right-or-first. scrolling:wrap_focus is off (so Mod + Left/Right
            -- stop at the edges); enable it just for this focus move.
            local function focusColumnWrapping(dir)
              return function()
                hl.config({ scrolling = { wrap_focus = true } })
                hl.dispatch(hl.dsp.layout("focus " .. dir))
                hl.config({ scrolling = { wrap_focus = false } })
              end
            end

            -- Other layouts cycle through the windows on the workspace instead.
            hl.bind(mainMod .. " + Tab", perLayout({
              scrolling = focusColumnWrapping("r"),
              default = hl.dsp.window.cycle_next(),
            }), { description = "Focus column right or first" })
            hl.bind(mainMod .. " + SHIFT + Tab", perLayout({
              scrolling = focusColumnWrapping("l"),
              default = hl.dsp.window.cycle_next({ next = false }),
            }), { description = "Focus column left or last" })

            -- Move windows and columns ----------------------------------------------------

            -- Move the column left/right (other layouts swap the window instead)
            hl.bind(mainMod .. " + SHIFT + left", perLayout({
              scrolling = hl.dsp.layout("swapcol l"),
              default = hl.dsp.window.swap({ direction = "left" }),
            }), { description = "Move column left" })
            hl.bind(mainMod .. " + SHIFT + right", perLayout({
              scrolling = hl.dsp.layout("swapcol r"),
              default = hl.dsp.window.swap({ direction = "right" }),
            }), { description = "Move column right" })

            -- Move the window up/down within the column
            -- Like Niri's move-window-up/down-or-to-workspace-up/down: swap with the window
            -- above/below and move the window to the previous/next workspace when there is none
            local function moveWindowOrToWorkspace(dir, fallback)
              return function()
                local result = hl.dispatch(hl.dsp.window.swap({ direction = dir }))
                if not (result and result.ok) then
                  hl.dispatch(fallback)
                end
              end
            end

            local moveWindowToWorkspaceUp = ifWorkspaceAbove(hl.dsp.window.move({ workspace = "r-1" }))
            local moveWindowToWorkspaceDown = ifWorkspaceBelow(hl.dsp.window.move({ workspace = "r+1" }))

            -- Monocle stacks all windows in the same spot, so move to the workspace directly.
            hl.bind(mainMod .. " + SHIFT + up", perLayout({
              monocle = moveWindowToWorkspaceUp,
              default = moveWindowOrToWorkspace("up", moveWindowToWorkspaceUp),
            }), { description = "Move window up or to workspace up" })
            hl.bind(mainMod .. " + SHIFT + down", perLayout({
              monocle = moveWindowToWorkspaceDown,
              default = moveWindowOrToWorkspace("down", moveWindowToWorkspaceDown),
            }), { description = "Move window down or to workspace down" })

            -- Consume or expel the window into/out of the neighbouring column.
            hl.bind(mainMod .. " + bracketleft", perLayout({ scrolling = hl.dsp.layout("consume_or_expel prev") }), { description = "Consume or expel window left" })
            hl.bind(mainMod .. " + bracketright", perLayout({ scrolling = hl.dsp.layout("consume_or_expel next") }), { description = "Consume or expel window right" })
            hl.bind(mainMod .. " + period", perLayout({ scrolling = hl.dsp.layout("expel") }), { description = "Expel window from column" })

            -- Resize ----------------------------------------------------------------------

            -- Column width (scrolling) and window width (other layouts)
            hl.bind(mainMod .. " + minus", perLayout({
              scrolling = hl.dsp.layout("colresize -0.1"),
              default = hl.dsp.window.resize({ x = -100, y = 0, relative = true }),
            }), { description = "Decrease column width" })
            hl.bind(mainMod .. " + equal", perLayout({
              scrolling = hl.dsp.layout("colresize +0.1"),
              default = hl.dsp.window.resize({ x = 100, y = 0, relative = true }),
            }), { description = "Increase column width" })

            -- Window height
            hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { description = "Decrease window height" })
            hl.bind(mainMod .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { description = "Increase window height" })

            -- Cycle through scrolling:explicit_column_widths (default 0.333, 0.5, 0.667, 1,0
            hl.bind(mainMod .. " + R", perLayout({ scrolling = hl.dsp.layout("colresize +conf") }), { description = "Switch preset column width" })

            -- Widen the column to fill the space not used by other visible columns
            hl.bind(mainMod .. " + SHIFT + M", perLayout({ scrolling = hl.dsp.layout("fit expand") }), { description = "Expand column to available width" })

            -- Workspaces ------------------------------------------------------------------

            -- Switch workspaces with mainMod + [1-9]
            -- Move active window to a workspace with mainMod + SHIFT + [1-9]
            for i = 1, maxWorkspace do
              hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }), { description = "Switch to workspace " .. i })
              hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }), { description = "Move window to workspace " .. i })
              hl.bind(mainMod .. " + CTRL + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }), { description = "Move window to workspace " .. i })
            end

            -- Previous/next workspace on the monitor, within 1 to maxWorkspace
            hl.bind(mainMod .. " + Page_Down", ifWorkspaceBelow(hl.dsp.focus({ workspace = "r+1" })), { description = "Focus workspace down" })
            hl.bind(mainMod .. " + Page_Up", ifWorkspaceAbove(hl.dsp.focus({ workspace = "r-1" })), { description = "Focus workspace up" })
            hl.bind(mainMod .. " + mouse_down", ifWorkspaceBelow(hl.dsp.focus({ workspace = "r+1" })), { description = "Focus workspace down" })
            hl.bind(mainMod .. " + mouse_up", ifWorkspaceAbove(hl.dsp.focus({ workspace = "r-1" })), { description = "Focus workspace up" })
            hl.bind(mainMod .. " + CTRL + Page_Down", ifWorkspaceBelow(hl.dsp.window.move({ workspace = "r+1" })), { description = "Move window to workspace down" })
            hl.bind(mainMod .. " + CTRL + Page_Up", ifWorkspaceAbove(hl.dsp.window.move({ workspace = "r-1" })), { description = "Move window to workspace up" })
            hl.bind(mainMod .. " + CTRL + mouse_down", ifWorkspaceBelow(hl.dsp.window.move({ workspace = "r+1" })), { description = "Move window to workspace down" })
            hl.bind(mainMod .. " + CTRL + mouse_up", ifWorkspaceAbove(hl.dsp.window.move({ workspace = "r-1" })), { description = "Move window to workspace up" })

            -- Previous workspace
            hl.bind("ALT + grave", hl.dsp.focus({ workspace = "previous" }), { description = "Switch to previous workspace" })

            -- Monitors --------------------------------------------------------------------

            local monitorDirs = { Left = "l", Right = "r", Up = "u", Down = "d" }
            for key, dir in pairs(monitorDirs) do
              hl.bind("ALT + " .. key, hl.dsp.focus({ monitor = dir }), { description = "Focus monitor " .. key:lower() })
              hl.bind(mainMod .. " + ALT + " .. key, hl.dsp.workspace.move({ monitor = dir }), { description = "Move workspace to monitor " .. key:lower() })
              hl.bind(mainMod .. " + ALT + CTRL + " .. key, hl.dsp.window.move({ monitor = dir }), { description = "Move window to monitor " .. key:lower() })
              hl.bind(mainMod .. " + ALT + SHIFT + " .. key, hl.dsp.window.move({ monitor = dir }), { description = "Move window to monitor " .. key:lower() })
            end

            -- Focus monitor / move active workspace to monitor with ALT (+ SHIFT) + [1-3]
            for i = 1, 3 do
              hl.bind("ALT + " .. i, hl.dsp.focus({ monitor = i - 1 }), { description = "Focus monitor " .. i })
              hl.bind("ALT + SHIFT + " .. i, hl.dsp.workspace.move({ monitor = i - 1 }), { description = "Move workspace to monitor " .. i })
            end

            -- Groups ----------------------------------------------------------------------

            hl.bind(mainMod .. " + G", hl.dsp.group.toggle(), { description = "Toggle the current active window into a group" })
            hl.bind(mainMod .. " + CTRL + Right", hl.dsp.group.next(), { description = "Switch to the next window in a group" })
            hl.bind(mainMod .. " + CTRL + Left", hl.dsp.group.prev(), { description = "Switch to the previous window in a group" })
            hl.bind(mainMod .. " + CTRL + SHIFT + Right", hl.dsp.window.move({ direction = "right", group_aware = true }), { description = "Move the active window into right group" })
            hl.bind(mainMod .. " + CTRL + SHIFT + Left", hl.dsp.window.move({ direction = "left", group_aware = true }), { description = "Move the active window into left group" })
          '';
        };

        home.file.".config/uwsm/env".text = ''
          # Hint electron apps to use wayland
          export NIXOS_OZONE_WL=1;
          export QT_QPA_PLATFORMTHEME=qt6ct;

          # Cursor size
          export XCURSOR_SIZE=16
          export HYPRCURSOR_SIZE=16

          # Force all apps to use Wayland
          export GDK_BACKEND="wayland,x11,*"
          export QT_QPA_PLATFORM="wayland;xcb"
          export QT_STYLE_OVERRIDE=kvantum
          export SDL_VIDEODRIVER=wayland
          export MOZ_ENABLE_WAYLAND=1
          export ELECTRON_OZONE_PLATFORM_HINT=wayland
          export OZONE_PLATFORM=wayland
        '';

        home.file.".config/uwsm/env-hyprland".text = ''
          # Cursor size
          export HYPRCURSOR_SIZE=16
        '';

        # xdg.portal = {
        #   extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        # };
      };

      system.env = {
        # Hint electron apps to use wayland
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORMTHEME = "qt6ct";
      };
    };

    # Desktop portal
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gnome
        pkgs.xdg-desktop-portal-gtk
      ];
      config.common = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      };
    };

    environment.systemPackages = with pkgs; [
      gnome-calculator
      imv
      mpv
      sushi
      jq
      impala
      bluetui
      wiremix
      pamixer
      wl-clipboard
      nwg-displays
      libqalculate
      libnotify
    ];
    # Custom scripts
    # ++ (import ./scripts { inherit pkgs; });

    # nwg-displays config files
    antob.persistence.home.files = [
      ".config/hypr/monitors.lua"
      ".config/hypr/monitors.conf"
      ".config/hypr/workspaces.conf"
    ];

    systemd.services."getty@tty1" = mkIf config.antob.user.autoLogin {
      overrideStrategy = "asDropin";
      serviceConfig.ExecStart = [
        ""
        "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${config.services.getty.loginProgram} --autologin ${config.antob.user.name} --noclear --keep-baud %I 115200,38400,9600 $TERM"
      ];
    };

    environment.loginShellInit = ''
      if uwsm check may-start -q; then
        # Load Home Manager session vars before uwsm snapshots the environment;
        # login zsh only sources them from ~/.zprofile, which runs after this.
        hmVars="/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
        [ -r "$hmVars" ] && . "$hmVars"
        exec uwsm start hyprland-uwsm.desktop
      fi
    '';
  };
}

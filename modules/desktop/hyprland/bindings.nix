{
  flake.modules.homeManager.hyprland =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) getExe optionalString;
      dm-firefox-profile = getExe (
        pkgs.callPackage ../_scripts/dm-firefox-profile.nix { config = osConfig; }
      );
      dm-herdr-session = getExe (
        pkgs.callPackage ../_scripts/dm-herdr-session.nix { config = osConfig; }
      );
      dm-keybindings = getExe (pkgs.callPackage ./_files/scripts/dm-keybindings.nix { });
      cmd-launch-webapp = getExe (
        pkgs.callPackage ../_scripts/cmd-launch-webapp.nix { inherit (osConfig.antob.rofi) launchPrefix; }
      );
      dm-vpn =
        if osConfig.antob ? networkd-vpn then
          getExe (pkgs.callPackage ../_scripts/dm-networkd-vpn.nix { config = osConfig; })
        else
          getExe (pkgs.callPackage ../_scripts/dm-nm-vpn.nix { });
    in
    {
      # Lua fragment 3 of 4: shared locals and helpers, then app, menu and utility binds.
      wayland.windowManager.hyprland.extraConfig = lib.mkOrder 300 /* lua */ ''
        ----------------------------------------------------------------------------
        -- Keybindings
        -- https://wiki.hypr.land/Configuring/Basics/Binds/
        ----------------------------------------------------------------------------

        local mainMod = "SUPER"
        local ipc = "noctalia msg "

        local terminal = "uwsm app -- ${pkgs.kitty}/bin/kitty"
        local tmuxTerminal = "uwsm app -- ${pkgs.kitty}/bin/kitty tmux-attach-unused"
        local tuiTerminal = "uwsm app -- ${pkgs.alacritty}/bin/alacritty"
        local browser = "uwsm app -- firefox"
        -- Unused
        -- local chromium = "uwsm app -- chromium --app="

        -- New scrolling columns open full width. On ultrawide monitors (aspect ratio
        -- of at least 2) a column that starts alone is shrunk to 2/3 of the width.
        local ultrawideRatio = 2
        local ultrawideColumnWidth = 0.667
        hl.on("window.open", function(w)
          if w.floating then return end
          local id = w.stable_id
          hl.timer(function()
            local active = hl.get_active_window()
            if not (active and active.stable_id == id) or active.floating then return end
            -- Fullscreen keeps the column width, so games would not fill the monitor
            if (active.fullscreen or 0) ~= 0 or active.class:match("^gamescope$") or active.class:match("^steam_app_") then return end
            local ws = active.workspace
            local mon = active.monitor
            local col = active.layout and active.layout.column
            if not (ws and not ws.special and ws.tiled_layout == "scrolling" and mon and col) then return end
            if mon.width / mon.height < ultrawideRatio then return end
            -- Skip a window that joined an existing column or was already resized
            if col.windows and #col.windows > 1 then return end
            if col.width < 0.999 then return end
            hl.dispatch(hl.dsp.layout("colresize " .. ultrawideColumnWidth))
          end, { timeout = 1, type = "oneshot" })
        end)

        -- Pick the dispatcher for the active workspace's tiled layout (scrolling,
        -- master, monocle, dwindle), falling back to `default`. An open special
        -- workspace takes precedence, as layout messages go to it.
        local function perLayout(dispatchers)
          return function()
            local ws = hl.get_active_special_workspace() or hl.get_active_workspace()
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
        -- Scratchpads: centred floating apps, each on its own special workspace.
        -- Mod + grave toggles the last used one; Mod + Left/Right step between them while open.
        local scratchpads = {
          { name = "music", class = "chrome-music.antob.net__-Default", cmd = "${cmd-launch-webapp} https://music.antob.net", size = 0.7 },
          { name = "term", class = "scratchpad", cmd = terminal .. " --class scratchpad", size = 0.7 },
        }
        local lastScratchpad = 1
        -- All scratchpads share one width fraction, capped in logical px for ultrawide monitors
        local scratchpadWidth = 0.7
        local scratchpadMaxWidth = 1800

        -- Enabled only while a scratchpad launches its app, so launcher starts open normally
        for _, s in ipairs(scratchpads) do
          s.ws = "special:" .. s.name
          s.rule = hl.window_rule({
            name = "scratchpad-" .. s.name,
            enabled = false,
            match = { class = "^" .. (s.class:gsub("%.", "\\.")) .. "$" },
            float = true,
            center = true,
            size = { "monitor_w*" .. scratchpadWidth, "monitor_h*" .. s.size },
            max_size = { scratchpadMaxWidth, 100000 },
            workspace = s.ws .. " silent",
          })
        end

        -- set_enabled re-applies every rule to every window, so skip it when already off
        local function disableRule(s)
          if s.rule:is_enabled() then s.rule:set_enabled(false) end
        end

        hl.on("window.open", function(win)
          for _, s in ipairs(scratchpads) do
            if win.class == s.class then disableRule(s) end
          end
        end)

        -- Overview: every running scratchpad app tiled together on one special workspace.
        hl.layout.register("grid", {
          recalculate = function(ctx)
            local n = #ctx.targets
            local cols = math.ceil(math.sqrt(n))
            for i, target in ipairs(ctx.targets) do
              target:place(n <= 3 and ctx:column(i, n) or ctx:grid_cell(i, cols))
            end
          end,
        })

        local overview = "scratchpads"
        local overviewWs = "special:" .. overview
        hl.workspace_rule({ workspace = overviewWs, layout = "grid" })

        local function activeSpecial()
          local special = hl.get_active_special_workspace()
          return special and special.name
        end

        local function overviewOpen()
          return activeSpecial() == overviewWs
        end

        local function visibleScratchpad()
          local name = activeSpecial()
          for i, s in ipairs(scratchpads) do
            if name == s.ws then return i end
          end
        end

        local function scratchpadIndex(class)
          for i, s in ipairs(scratchpads) do
            if s.class == class then return i end
          end
        end

        local function onWorkspace(win, ws)
          return win.workspace and win.workspace.name == ws
        end

        local function eachScratchpadWindow(fn)
          for _, s in ipairs(scratchpads) do
            for _, win in ipairs(hl.get_windows({ class = s.class })) do fn(win, s) end
          end
        end

        local function withoutAnim(anim, fn)
          hl.animation({ leaf = anim.leaf, enabled = false })
          fn()
          hl.timer(function() hl.animation(anim) end, { timeout = 50, type = "oneshot" })
        end

        local function placeScratchpad(win, s)
          hl.dispatch(hl.dsp.window.move({ workspace = s.ws, follow = false, window = win }))
          hl.dispatch(hl.dsp.window.float({ action = "enable", window = win }))
          local mon = win.monitor
          if mon then
            local w = math.min(mon.width / mon.scale * scratchpadWidth, scratchpadMaxWidth)
            hl.dispatch(hl.dsp.window.resize({ x = w, y = mon.height / mon.scale * s.size, window = win }))
          end
          hl.dispatch(hl.dsp.window.center({ window = win }))
        end

        local function scratchpadWindow(s)
          local wins = hl.get_windows({ class = s.class })
          for _, win in ipairs(wins) do
            if onWorkspace(win, s.ws) then return win end
          end
          return wins[1]
        end

        -- Launch the app, or pull it in if it was opened elsewhere or tiled, then show it.
        local function showScratchpad(i)
          local s = scratchpads[i]
          local win = scratchpadWindow(s)
          if not win then
            s.rule:set_enabled(true)
            hl.exec_cmd(s.cmd)
            -- In case the app never opens a window
            hl.timer(function() disableRule(s) end, { timeout = 15000, type = "oneshot" })
          elseif not (win.floating and onWorkspace(win, s.ws)) then
            placeScratchpad(win, s)
          end
          hl.dispatch(hl.dsp.workspace.toggle_special(s.name))
          lastScratchpad = i
        end

        local function hideScratchpad()
          local i = visibleScratchpad()
          if i then hl.dispatch(hl.dsp.workspace.toggle_special(scratchpads[i].name)) end
          return i
        end

        -- windowsMove is off so the windows are already tiled as the overview slides in
        local function openOverview()
          withoutAnim(windowsMoveAnim, function()
            local found = false
            eachScratchpadWindow(function(win, s)
              if onWorkspace(win, s.ws) or onWorkspace(win, overviewWs) then
                hl.dispatch(hl.dsp.window.move({ workspace = overviewWs, follow = false, window = win }))
                hl.dispatch(hl.dsp.window.float({ action = "disable", window = win }))
                found = true
              end
            end)
            if found then hl.dispatch(hl.dsp.workspace.toggle_special(overview)) end
          end)
        end

        -- Wait for the overview to slide out; moving windows earlier cuts the animation short
        local function restoreOverviewLater()
          hl.timer(function()
            if overviewOpen() then return end
            eachScratchpadWindow(function(win, s)
              if onWorkspace(win, overviewWs) then placeScratchpad(win, s) end
            end)
          end, { timeout = math.ceil(slideSpeed * 100) + 50, type = "oneshot" })
        end

        local function closeOverview()
          hl.dispatch(hl.dsp.workspace.toggle_special(overview))
          restoreOverviewLater()
        end

        hl.bind(mainMod .. " + grave", function()
          if overviewOpen() then
            local active = hl.get_active_window()
            lastScratchpad = (active and scratchpadIndex(active.class)) or lastScratchpad
            showScratchpad(lastScratchpad)
            restoreOverviewLater()
          elseif not hideScratchpad() then
            showScratchpad(lastScratchpad)
          end
        end, { description = "Toggle scratchpad" })

        -- While a scratchpad is open, step to the previous/next app without the slide animation
        local function scratchpadOr(step, fallback)
          return function()
            local i = visibleScratchpad()
            if not i then return fallback() end
            withoutAnim(specialWorkspaceAnim, function()
              showScratchpad((i - 1 + step) % #scratchpads + 1)
            end)
          end
        end
        hl.bind("CTRL + grave", function()
          if overviewOpen() then closeOverview() else openOverview() end
        end, { description = "Scratchpad overview" })
        hl.bind(mainMod .. " + Escape", function()
          if overviewOpen() then closeOverview() else hideScratchpad() end
        end, { description = "Hide scratchpad" })
        hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("uwsm app -- nautilus --new-window"), { description = "File manager" })
        hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(browser), { description = "Web browser" })
        hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("${dm-firefox-profile}"), { description = "Select Firefox profile" })
        hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(tuiTerminal .. " --class=TUI.float.lg -e ${pkgs.impala}/bin/impala"), { description = "WIFI" })
        hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(tuiTerminal .. " --class=TUI.float.lg -e ${getExe pkgs.bluetui}"), { description = "Bluetooth" })
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
        -- The MX Mechanical Mini screenshot key sends Super+Shift+S in Windows mode.
        hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(ipc .. "screenshot-region"), { description = "Screenshot of region" })
        ${optionalString (osConfig.antob ? voxtype) ''
          -- The MX Mechanical Mini dictation key sends Super+H in Windows mode.
          hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("voxtype record start"), { description = "Start voice dictation" })
          hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("voxtype record stop"), { release = true, description = "Stop voice dictation" })
        ''}
        hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("pkill hyprpicker || ${getExe pkgs.hyprpicker} -a"), { description = "Color picker" })
      '';
    };
}

{
  flake.modules.homeManager.hyprland =
    { lib, ... }:
    {
      # Lua fragment 4 of 4: layout, window, focus, workspace, monitor and group binds.
      # Uses the locals and helpers (mainMod, ipc, perLayout, ...) defined in bindings.nix.
      wayland.windowManager.hyprland.extraConfig = lib.mkOrder 400 /* lua */ ''
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
        -- Toggle the column between full width and its previous width (scrolling),
        -- or maximize (other layouts). Previous widths are keyed by window stable_id.
        local prevColumnWidth = {}
        hl.bind(mainMod .. " + M", perLayout({
          scrolling = function()
            local w = hl.get_active_window()
            local col = w and w.layout and w.layout.column
            if not col then
              return
            end
            local prev = prevColumnWidth[w.stable_id]
            if col.width >= 0.999 and prev then
              prevColumnWidth[w.stable_id] = nil
              hl.dispatch(hl.dsp.layout("colresize " .. prev))
            elseif col.width < 0.999 then
              prevColumnWidth[w.stable_id] = col.width
              hl.dispatch(hl.dsp.layout("colresize 1.0"))
            end
          end,
          default = hl.dsp.window.fullscreen({ mode = "maximized" }),
        }), { description = "Toggle full-width column / maximize window" })

        -- Pop the window out (float, pin, center) or put it back
        hl.bind(mainMod .. " + O", function()
          local w = hl.get_active_window()
          if not w then
            return
          end
          if w.pinned then
            hl.dispatch(hl.dsp.window.pin({ window = w }))
            hl.dispatch(hl.dsp.window.float({ action = "disable", window = w }))
          else
            hl.dispatch(hl.dsp.window.float({ action = "enable", window = w }))
            hl.dispatch(hl.dsp.window.resize({ x = 1300, y = 900, window = w }))
            hl.dispatch(hl.dsp.window.center({ window = w }))
            hl.dispatch(hl.dsp.window.pin({ window = w }))
            hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = w }))
          end
        end, { description = "Pop window out / back in" })

        -- Switch focus between floating and tiled windows
        hl.bind(mainMod .. " + SHIFT + V", function()
          local w = hl.get_active_window()
          hl.dispatch(hl.dsp.focus({ window = (w and w.floating) and "tiled" or "floating" }))
        end, { description = "Switch focus between floating and tiling" })

        -- Move/resize windows with mainMod + LMB/RMB and dragging
        hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window" })
        hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

        -- Focus -----------------------------------------------------------------------

        -- Move focus within the column and go to the previous/next workspace at the
        -- top/bottom. general:no_focus_fallback
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

        hl.bind(mainMod .. " + left", scratchpadOr(-1, perLayout({
          scrolling = hl.dsp.layout("focus l"),
          monocle = hl.dsp.layout("cycleprev"),
          default = hl.dsp.focus({ direction = "left" }),
        })), { description = "Move focus left or previous scratchpad" })
        hl.bind(mainMod .. " + right", scratchpadOr(1, perLayout({
          scrolling = hl.dsp.layout("focus r"),
          monocle = hl.dsp.layout("cyclenext"),
          default = hl.dsp.focus({ direction = "right" }),
        })), { description = "Move focus right or next scratchpad" })

        -- Focus next/previous column, wrapping around at the ends.
        -- scrolling:wrap_focus is off (so Mod + Left/Right
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
        -- Swap with the window above/below and move the window to the previous/next
        -- workspace when there is none
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

        -- Cycle through scrolling:explicit_column_widths (default 0.333, 0.5, 0.667, 1.0)
        hl.bind(mainMod .. " + R", perLayout({ scrolling = hl.dsp.layout("colresize +conf") }), { description = "Switch preset column width" })

        -- Workspaces ------------------------------------------------------------------

        -- Switch workspaces with mainMod + [1-9]
        -- Move active window to a workspace with mainMod + SHIFT + [1-9]
        for i = 1, maxWorkspace do
          hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }), { description = "Switch to workspace " .. i })
          hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }), { description = "Move window to workspace " .. i })
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

        -- Same pattern as windows: plain focuses, SHIFT moves the window
        local monitorDirs = { left = "l", right = "r", up = "u", down = "d" }
        for key, dir in pairs(monitorDirs) do
          hl.bind(mainMod .. " + ALT + " .. key, hl.dsp.focus({ monitor = dir }), { description = "Focus monitor " .. key })
          hl.bind(mainMod .. " + ALT + SHIFT + " .. key, hl.dsp.window.move({ monitor = dir }), { description = "Move window to monitor " .. key })
          hl.bind(mainMod .. " + ALT + CTRL + " .. key, hl.dsp.workspace.move({ monitor = dir }), { description = "Move workspace to monitor " .. key })
        end
        hl.bind(mainMod .. " + backslash", hl.dsp.focus({ monitor = "+1" }), { description = "Focus next monitor" })

        -- Touchpad gestures ----------------------------------------------------------
        -- 3 fingers vertical switches workspace, horizontal moves between columns.

        hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })
        hl.gesture({ fingers = 3, direction = "left", action = perLayout({
          scrolling = hl.dsp.layout("focus r"),
          monocle = hl.dsp.layout("cyclenext"),
          default = hl.dsp.focus({ direction = "right" }),
        }) })
        hl.gesture({ fingers = 3, direction = "right", action = perLayout({
          scrolling = hl.dsp.layout("focus l"),
          monocle = hl.dsp.layout("cycleprev"),
          default = hl.dsp.focus({ direction = "left" }),
        }) })

        -- Groups ----------------------------------------------------------------------

        hl.bind(mainMod .. " + G", hl.dsp.group.toggle(), { description = "Toggle the current active window into a group" })
        hl.bind(mainMod .. " + CTRL + right", hl.dsp.group.next(), { description = "Switch to the next window in a group" })
        hl.bind(mainMod .. " + CTRL + left", hl.dsp.group.prev(), { description = "Switch to the previous window in a group" })
        hl.bind(mainMod .. " + CTRL + SHIFT + right", hl.dsp.window.move({ direction = "right", group_aware = true }), { description = "Move the active window into right group" })
        hl.bind(mainMod .. " + CTRL + SHIFT + left", hl.dsp.window.move({ direction = "left", group_aware = true }), { description = "Move the active window into left group" })
      '';
    };
}

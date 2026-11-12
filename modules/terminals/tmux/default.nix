{ config, ... }:
let
  inherit (config.flake.lib) mkBoolOpt mixColors;
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.tmux =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    {
      options.antob.tmux = {
        addTerminalKeybindings = mkBoolOpt true "Whether or not to add keybindings to terminals in tmux.";
      };

      config = {
        home-manager.sharedModules = [ homeManager.tmux ];

        environment.systemPackages = with pkgs; [
          (writeShellScriptBin "tmux-attach-unused" ''
            tmux attach 2> /dev/null -t $(tmux ls 2> /dev/null | grep -v attached | cut -f1 -d: | grep -E "^[0-9]+$" | head -1) || tmux
          '')
          sesh
          wl-clipboard
        ];

        antob.persistence.home.directories = [ ".local/share/tmux" ];
      };
    };

  flake.modules.homeManager.tmux =
    {
      config,
      osConfig,
      lib,
      pkgs,
      ...
    }:
    with lib;
    let
      cfg = osConfig.antob.tmux;
      configFiles = mapAttrsToList (name: _: "${./_files/config}/${name}") (
        filterAttrs (_: kind: kind == "regular") (builtins.readDir ./_files/config)
      );
      c = osConfig.lib.stylix.colors.withHashtag;
      # No-break space: kitty widens nerd font icons into a following regular space
      nbsp = builtins.fromJSON ''"\u00a0"'';
      windowText = "#{?#{m:* pi *, #{P:#{@agent} }},#[fg=${c.base0D}]π ,}#{?#{m:* claude *, #{P:#{@agent} }},#[fg=${c.base09}]✻ ,}#[fg=${c.base05}]#W#{?@workmux_status, #{s/🤖/󰚩/:@workmux_status},}";
      # Catppuccin's basic layout (number block + title block), coloured from Stylix.
      theme = /* tmux */ ''
        set -g status-style "bg=${mixColors osConfig.lib.stylix.colors "base01" "base02"},fg=${c.base05}"
        set -g message-style "fg=${c.base0C},bg=${c.base03},align=centre"
        set -g message-command-style "fg=${c.base0C},bg=${c.base03},align=centre"
        set -g menu-selected-style "fg=${c.base05},bold,bg=${c.base03}"
        set -g popup-style "bg=${c.base01},fg=${c.base05}"
        set -g popup-border-style "fg=${c.base03}"
        set -g pane-border-style "fg=${c.base03}"
        set -g pane-active-border-style "fg=${c.base0C}"
        set -g mode-style "bg=${c.base02},bold"
        set -g clock-mode-colour "${c.base0D}"

        set -g window-status-activity-style "bg=${c.base0D},fg=${c.base00}"
        set -g window-status-bell-style "bg=${c.base0A},fg=${c.base00}"
        set -g window-status-current-style default
        set -g window-status-format "#[fg=${c.base00},bg=${c.base04}] #I #[fg=${c.base05},bg=${c.base02}] ${windowText}${nbsp}"
        set -g window-status-current-format "#[fg=${c.base00},bg=${c.base0E}] #I #[fg=${c.base05},bg=${c.base03}] ${windowText}${nbsp}"
      '';
      # Session module: block turns red while the prefix is active.
      sessionIcon = builtins.fromJSON ''"\ue795"'';
      sessionColor = "#{?client_prefix,${c.base08},${c.base0B}}";
      statusSession = "#[fg=${sessionColor}]█#[fg=${c.base00},bg=${sessionColor}]${sessionIcon} #[fg=${c.base05},bg=${c.base02}] #S#[fg=${c.base02}] ";
      tmuxColumns = pkgs.writeShellApplication {
        name = "tmux-columns";
        runtimeInputs = [
          config.programs.tmux.package
          pkgs.jq
        ];
        # jq programs use $vars inside single quotes
        excludeShellChecks = [ "SC2016" ];
        text = builtins.readFile ./_files/tmux-columns.sh;
      };
      # Ctrl+Shift+Enter: new column right of this one; prefix Down/Right: split within the column;
      # prefix Shift+Left/Right: swap the column with its neighbour.
      columns = /* tmux */ ''
        bind -n \uE010 run-shell "${getExe tmuxColumns} new '#{pane_id}'"
        bind Down run-shell "${getExe tmuxColumns} down '#{pane_id}'"
        bind Right run-shell "${getExe tmuxColumns} right '#{pane_id}'"
        # Repeatable: keep tapping Shift+Left/Right within repeat-time to keep moving the column
        bind -r S-Left run-shell "${getExe tmuxColumns} swap '#{pane_id}' left"
        bind -r S-Right run-shell "${getExe tmuxColumns} swap '#{pane_id}' right"
        # Snapshot layouts on split and focus change, so closing a pane evens out its container
        # and moves focus within its column
        set-hook -g after-split-window "run-shell '${getExe tmuxColumns} snapshot'"
        set-hook -g after-select-pane "run-shell -b '${getExe tmuxColumns} snapshot #{window_id}'"
        set-hook -g after-kill-pane "run-shell '${getExe tmuxColumns} closed'"
        set-hook -g pane-exited "run-shell '${getExe tmuxColumns} closed'"
      '';
      # Plain capture-pane hides OSC 8 link targets behind their names; append them via -H (tmux 3.8+)
      extrakto = pkgs.tmuxPlugins.extrakto.overrideAttrs {
        postPatch = ''
          substituteInPlace extrakto_plugin.py --replace-fail "        return captured" '
                  panes = [self.trigger_pane]
                  if self.grab_area.startswith("window"):
                      panes = subprocess.check_output(
                          ["tmux", "list-panes", "-F", "#{pane_id}"], universal_newlines=True
                      ).split()
                  for pane in panes:
                      captured += "\n" + subprocess.check_output(
                          ["tmux", "capture-pane", "-pHS", capture_pane_start, "-t", pane],
                          universal_newlines=True,
                      )
                  return captured'
        '';
      };
      alacritty = config.programs.alacritty.enable;
      kitty = config.programs.kitty.enable;
      plugins = with pkgs; [
        tmuxPlugins.sensible
        tmuxPlugins.tmux-fzf
        {
          plugin = extrakto;
          extraConfig = ''
            # "auto" picks xclip when XWayland sets $DISPLAY
            set -g @extrakto_clip_tool 'wl-copy'
            set -g @extrakto_filter_order 'url word path all line'
            # popup -w/-h take no formats and error when larger than the client, so cap at 120x40 per open
            set -g @extrakto_key 'none'
            bind Tab set -gF @extrakto_popup_size '#{?#{e|>:#{client_width},133},120,90%},#{?#{e|>:#{client_height},44},40,90%}' \; \
              run-shell "${extrakto}/share/tmux-plugins/extrakto/scripts/open.sh '#{pane_id}'"
          '';
        }
        {
          plugin = tmuxPlugins.resurrect;
          extraConfig = ''
            set -g @resurrect-dir '~/.local/share/tmux/resurrect'
            set -g @resurrect-save 'S'
            set -g @resurrect-restore 'R'
          '';
        }
        {
          plugin = tmuxPlugins.continuum;
          extraConfig = ''
            # Must be set before continuum loads: it appends its autosave hook to status-right
            set -g status-right "${statusSession}"
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '5'
          '';
        }
      ];
    in
    {
      programs = {
        tmux = {
          enable = true;
          clock24 = true;
          terminal = "tmux-256color";
          historyLimit = 100000;
          extraConfig = builtins.concatStringsSep "\n" (
            map lib.strings.fileContents configFiles
            ++ [
              theme
              columns
            ]
          );

          inherit plugins;
        };

        alacritty.settings.keyboard.bindings = lib.mkIf (cfg.addTerminalKeybindings && alacritty) [
          ## Make Alacritty send Control+Shift keys
          # Cycle layout
          {
            key = "l";
            mods = "Control|Shift";
            chars = "\\uE000";
          }
          # Spawn new pane
          {
            key = "Return";
            mods = "Control|Shift";
            chars = "\\uE010";
          }
          # Toggle pane zoom
          {
            key = "m";
            mods = "Control|Shift";
            chars = "\\uE011";
          }
          # Spawn new window
          {
            key = "t";
            mods = "Control|Shift";
            chars = "\\uE020";
          }
          # Focus previous window
          {
            key = "{";
            mods = "Control|Shift";
            chars = "\\uE021";
          }
          # Focus next window
          {
            key = "}";
            mods = "Control|Shift";
            chars = "\\uE022";
          }
          # Move window left
          {
            key = "{";
            mods = "Control|Shift|Alt";
            chars = "\\uE023";
          }
          # Move window right
          {
            key = "}";
            mods = "Control|Shift|Alt";
            chars = "\\uE024";
          }
          # Make Alacritty send Shift+Enter for new line in tmux
          {
            key = "Return";
            mods = "Shift";
            chars = "\\u001b[13;2u";
          }
        ];

        kitty.keybindings = lib.mkIf (cfg.addTerminalKeybindings && kitty) {
          # Pass Shift+Enter through tmux to inner applications
          "shift+enter" = "send_text all \\x1b[13;2u";

          ## Make Kitty send Control+Shift keys
          # Cycle layout
          "ctrl+shift+l" = "send_text all \\uE000";

          # Spawn new pane
          "ctrl+shift+enter" = "send_text all \\uE010";

          # Toggle pane zoom
          "ctrl+shift+m" = "send_text all \\uE011";

          # Spawn new window
          "ctrl+shift+t" = "send_text all \\uE020";

          # Focus previous window
          "ctrl+shift+[" = "send_text all \\uE021";

          # Focus next window
          "ctrl+shift+]" = "send_text all \\uE022";

          # Move focused window left
          "ctrl+shift+alt+[" = "send_text all \\uE023";

          # Move focused window right
          "ctrl+shift+alt+]" = "send_text all \\uE024";
        };
      };

    };

}

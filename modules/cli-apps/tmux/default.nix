{ config, ... }:
let
  inherit (config.flake.lib) mkBoolOpt;
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
      options.antob.tmux = with types; {
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
      colors = osConfig.antob.color-scheme.colors;
      alacritty = config.programs.alacritty.enable;
      kitty = config.programs.kitty.enable;
      plugins = with pkgs; [
        tmuxPlugins.sensible
        tmuxPlugins.tmux-fzf
        {
          plugin = tmuxPlugins.resurrect;
          extraConfig = ''
            set -g @resurrect-dir '~/.local/share/tmux/resurrect'
            set -g @resurrect-save 'S'
            set -g @resurrect-restore 'R'
          '';
        }
        {
          plugin = tmuxPlugins.catppuccin;
          extraConfig = /* tmux */ ''
            set -g @catppuccin_flavor "frappe"
            set -g @catppuccin_status_left_separator "█"
            # No-break space: kitty widens nerd font icons into a following regular space
            set -g @catppuccin_window_right_separator " "
            set -g @catppuccin_pane_active_border_style "fg=#${colors.base0C}"
            set -ogq @catppuccin_window_text " #{?#{m:* pi *, #{P:#{@agent} }},#[fg=#{@thm_blue}]π ,}#{?#{m:* claude *, #{P:#{@agent} }},#[fg=#{@thm_peach}]✻ ,}#[fg=#{@thm_fg}]#W#{?@workmux_status, #{s/🤖/󰚩/:@workmux_status},}"
            set -ogq @catppuccin_window_current_text " #{?#{m:* pi *, #{P:#{@agent} }},#[fg=#{@thm_blue}]π ,}#{?#{m:* claude *, #{P:#{@agent} }},#[fg=#{@thm_peach}]✻ ,}#[fg=#{@thm_fg}]#W#{?@workmux_status, #{s/🤖/󰚩/:@workmux_status},}"
            # tmux 3.8 defaults to underscore
            set -g window-status-current-style default
          '';
        }
        {
          plugin = tmuxPlugins.continuum;
          extraConfig = ''
            # Must be set before continuum loads: it appends its autosave hook to status-right
            set -g status-right "#{E:@catppuccin_status_session}"
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '5'
          '';
        }
      ];
    in
    {
      programs.tmux = {
        enable = true;
        clock24 = true;
        terminal = "tmux-256color";
        historyLimit = 100000;
        extraConfig = builtins.concatStringsSep "\n" (map lib.strings.fileContents configFiles);

        inherit plugins;
      };

      programs.alacritty.settings.keyboard.bindings = lib.mkIf (cfg.addTerminalKeybindings && alacritty) [
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

      programs.kitty.keybindings = lib.mkIf (cfg.addTerminalKeybindings && kitty) {
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

}

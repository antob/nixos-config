{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.tools.kitty;
  colors = config.antob.color-scheme.colors;
in
{
  options.antob.tools.kitty = with types; {
    enable = mkEnableOption "Enable kitty";
    fontSize = mkOpt int 12 "Font size.";
  };

  config = mkIf cfg.enable {
    antob.persistence.home.directories = [
      ".local/share/kitty"
      ".cache/kitty"
    ];

    antob.home.extraOptions =
      let
        baseConfig = /* kitty */ ''
          font_family Jetbrains Mono
          font_size ${toString cfg.fontSize}

          shell_integration no-rc

          allow_remote_control socket-only
          background_opacity 1.0
          clear_all_shortcuts yes
          confirm_os_window_close 0
          cursor_shape beam
          disable_ligatures always
          enable_audio_bell no
          enabled_layouts tall,vertical,horizontal,grid,stack
          hide_window_decorations yes
          listen_on unix:/tmp/kitty.sock
          scrollback_lines 10000
          tab_bar_style separator
          tab_separator  | 
          term xterm-256color
          undercurl_style thick-sparse
          url_color #${colors.base06}
          url_style straight
          window_border_width 1pt
          window_padding_width 4

          env TERM=xterm-256color

          map ctrl+shift+0 change_font_size all 0
          map ctrl+shift+c copy_to_clipboard
          map ctrl+shift+equal change_font_size all +1.0
          map ctrl+shift+f search_scrollback
          map ctrl+shift+minus change_font_size all -1.0
          map ctrl+shift+p command_palette
          map ctrl+shift+page_down scroll_page_down
          map ctrl+shift+page_up scroll_page_up
          map ctrl+shift+v paste_from_clipboard
          map ctrl+shift+x scroll_to_prompt 1
          map ctrl+shift+z scroll_to_prompt -1

          include ${./themes/tokyonight-night.conf}
          active_border_color #${colors.base0C}
          inactive_border_color #${colors.base12}
        '';
      in
      {
        xdg.configFile."kitty/kitty.conf".text = /* kitty */ ''
          ${baseConfig}

          map ctrl+shift+[ send_text all \uE021
          map ctrl+shift+] send_text all \uE022
          map ctrl+shift+alt+[ send_text all \uE023
          map ctrl+shift+alt+] send_text all \uE024
          map ctrl+shift+enter send_text all \uE010
          map ctrl+shift+l send_text all \uE000
          map ctrl+shift+m send_text all \uE011
          map ctrl+shift+t send_text all \uE020
          map shift+enter send_text all \x1b[13;2u
        '';

        xdg.configFile."kitty/kitty-no-bindings.conf".text = /* kitty */ ''
          ${baseConfig}
        '';

        programs.zsh.initContent = /* bash */ ''
          if test -n "$KITTY_INSTALLATION_DIR"; then
            export KITTY_SHELL_INTEGRATION="no-rc"
            autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
            kitty-integration
            unfunction kitty-integration
          fi
        '';
      };
  };
}

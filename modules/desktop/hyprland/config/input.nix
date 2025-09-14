{ }:
''
  # https://wiki.hyprland.org/Configuring/Variables/#input
  input {
    kb_layout = se
    kb_variant = us
    kb_model =
    kb_options = caps:ctrl_modifier # compose:caps
    # kb_options = compose:caps
    kb_rules =

    repeat_rate = 30
    repeat_delay = 200
    follow_mouse = 1
    sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

    touchpad {
      natural_scroll = true
      # Control the speed of your scrolling
      scroll_factor = 0.4
    }
  }

  # https://wiki.hyprland.org/Configuring/Variables/#cursor
  cursor {
    hide_on_key_press = true
    inactive_timeout = 10
  }

  # Scroll faster in the terminal
  windowrule = scrolltouchpad 1.5, class:Alacritty
''

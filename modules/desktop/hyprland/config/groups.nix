{
  config,
  ...
}:

let
  colors = config.antob.color-scheme.colors;
in
''
  # https://wiki.hyprland.org/Configuring/Variables/#group
  group {
    focus_removed_window = true

    col.border_active = rgba(${colors.base0D}ff)
    col.border_inactive = rgba(${colors.base12}aa)

    groupbar {
      enabled = false
    }
  }
''

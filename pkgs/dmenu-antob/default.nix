{
  dmenu,
  fetchFromGitHub,
}:

# Personal dmenu fork. Kept as a separate package instead of overriding
# `dmenu` globally, which would change uwsm/hyprland and miss the binary cache.
dmenu.overrideAttrs (oldAttrs: {
  pname = "dmenu-antob";
  src = fetchFromGitHub {
    owner = "antob";
    repo = "dmenu";
    rev = "cd3f248";
    sha256 = "sha256-OHvRuex2k72FJiVaMZkcmbpoKIgqpZzxrAImgg8XVeI=";
  };
})

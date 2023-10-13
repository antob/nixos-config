{ channels, ... }:

final: prev: {
  dmenu = prev.dmenu.overrideAttrs (oldAttrs: {
    src = prev.fetchFromGitHub {
      owner = "antob";
      repo = "dmenu";
      rev = "cd3f248";
      sha256 = "sha256-OHvRuex2k72FJiVaMZkcmbpoKIgqpZzxrAImgg8XVeI=";
    };
  });
}

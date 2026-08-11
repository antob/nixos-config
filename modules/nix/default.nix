{
  config,
  outputs,
  ...
}:

{
  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  nix = {
    # Remove nix-channel related tools & configs, we use flakes instead.
    channel.enable = false;

    settings = {
      experimental-features = "nix-command flakes";
      use-xdg-base-directories = true;
      http-connections = 50;
      warn-dirty = false;
      log-lines = 50;
      sandbox = "relaxed";
      auto-optimise-store = true;
      trusted-users = [
        "root"
        config.antob.user.name
      ];
      allowed-users = [
        "root"
        config.antob.user.name
      ];
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
        "https://nix-cache.antob.net"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-cache.antob.net-1:yrIa59Q68kwhCAU42Fh8p6FelDTyfcTWFEBDHRgY9C0="
      ];
    };
  };

  antob.persistence.home.directories = [
    ".local/share/nix"
  ];
}

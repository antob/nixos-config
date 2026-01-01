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
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  antob.persistence.home.directories = [
    ".local/share/nix"
  ];
}

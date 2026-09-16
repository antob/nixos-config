{
  config,
  outputs,
  ...
}:

let
  secrets = config.sops.secrets;
in
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
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      use-xdg-base-directories = true;
      http-connections = 50;
      warn-dirty = false;
      log-lines = 50;
      sandbox = "relaxed";
      auto-optimise-store = true;
      trusted-users = [
        config.antob.user.name
      ];
      allowed-users = [
        config.antob.user.name
      ];
      substituters = [
        "https://nix-community.cachix.org"
        "http://nix-cache.hyllan.lan"
        "https://nixos-raspberrypi.cachix.org"
      ];
      trusted-substituters = [
        "https://nix-community.cachix.org"
        "http://nix-cache.hyllan.lan"
        "https://nix-cache.antob.net"
        "https://nixos-raspberrypi.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-cache.hyllan.lan-1:yrIa59Q68kwhCAU42Fh8p6FelDTyfcTWFEBDHRgY9C0="
        "nix-cache.antob.net-1:yrIa59Q68kwhCAU42Fh8p6FelDTyfcTWFEBDHRgY9C0="
        "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      ];
    };

    extraOptions = ''
      !include ${secrets.nix_access_tokens.path}
    '';
  };

  sops.secrets.nix_access_tokens = {
    sopsFile = ../../hosts/common/secrets.yaml;
    group = "nixbld";
    mode = "0440";
  };

  antob.persistence.home.directories = [
    ".local/share/nix"
  ];
}

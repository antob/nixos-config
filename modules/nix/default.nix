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
      experimental-features = "nix-command flakes";
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
        "https://nix-cache.antob.net"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-cache.antob.net-1:yrIa59Q68kwhCAU42Fh8p6FelDTyfcTWFEBDHRgY9C0="
      ];
    };

    extraOptions = ''
      !include ${secrets.nix_access_tokens.path}
    '';
  };

  sops.secrets.nix_access_tokens.sopsFile = ../../hosts/common/secrets.yaml;

  antob.persistence.home.directories = [
    ".local/share/nix"
  ];
}

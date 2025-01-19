{
  config,
  lib,
  inputs,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.desktop.cosmic;
in
{
  imports = with inputs; [ nixos-cosmic.nixosModules.default ];

  options.antob.desktop.cosmic = with types; {
    enable = mkEnableOption "Enable Cosmic Desktop.";
  };

  config = mkIf cfg.enable {
    nix.settings = {
      substituters = [ "https://cosmic.cachix.org/" ];
      trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
    };

    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;

    # environment.systemPackages = with pkgs; [
    # ];

    antob.system.env = {
      MOZ_ENABLE_WAYLAND = "1";
    };
  };
}

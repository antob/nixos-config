{
  lib,
  pkgs,
  config,
  ...
}:

with lib;
let
  cfg = config.antob.services.tailscale;
in
{
  options.antob.services.tailscale = with types; {
    enable = mkBoolOpt false "Whether or not to configure Tailscale";
    extraUpFlags = mkOpt (listOf str) [ ] "List of flags to pass to tailscale up command.";
    keyfile = mkOpt str "" "File with authentication key to use";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ tailscale ];

    services.tailscale = {
      enable = true;
      authKeyFile = cfg.keyfile;
      useRoutingFeatures = "client";
      extraUpFlags = [
        "--login-server=https://hs.antob.se:443"
        "--accept-routes"
      ]
      ++ cfg.extraUpFlags;
    };

    networking = {
      firewall = {
        trustedInterfaces = [ config.services.tailscale.interfaceName ];

        allowedUDPPorts = [ config.services.tailscale.port ];

        # Strict reverse path filtering breaks Tailscale exit node use and some subnet routing setups.
        checkReversePath = "loose";
      };

      networkmanager.unmanaged = [ "tailscale0" ];
    };

    antob.persistence.directories = [ "/var/lib/tailscale" ];
  };
}

{ config, ... }:
let
  inherit (config.flake.lib) mkOpt;
in
{
  flake.modules.nixos.tailscale =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    with lib;
    let
      cfg = config.antob.tailscale;
    in
    {
      options.antob.tailscale = with types; {
        extraUpFlags = mkOpt (listOf str) [ ] "List of flags to pass to tailscale up command.";
        keyFile = mkOpt (nullOr str) null "File with authentication key to use";
      };

      config = {
        environment.systemPackages = with pkgs; [ tailscale ];

        services.tailscale = {
          enable = true;
          authKeyFile = mkIf (cfg.keyFile != null) cfg.keyFile;
          useRoutingFeatures = "client";
          inherit (cfg) extraUpFlags;
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

        antob.persistence.safe.directories = [ "/var/lib/tailscale" ];
      };
    };

}

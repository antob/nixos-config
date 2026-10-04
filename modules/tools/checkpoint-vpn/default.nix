{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.tools.checkpoint-vpn;
in
{
  options.antob.tools.checkpoint-vpn = with types; {
    enable = mkEnableOption "Whether or not to enable checkpoint-vpn.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      snx-rs
    ];

    systemd.services.snx-rs = {
      enable = true;
      description = "SNX-RS VPN client for Linux";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.snx-rs}/bin/snx-rs -m command -l debug";
        Type = "simple";
      };
    };

    # update the firewall rule to allow keepalive traffic
    networking.firewall.checkReversePath = "loose";

    # List the profiles in the dm-networkd-vpn menu. The attribute name must
    # match `if-name` in the profile, it is used to detect an active tunnel.
    antob.services.networkd-vpn.vpns.snx-puzzel = mkIf config.antob.services.networkd-vpn.enable {
      type = "snx";
      snxProfile = "Puzzel";
      label = "Puzzel VPN";
    };

    antob.home.extraOptions = {
      xdg.configFile."snx-rs/puzzel.conf".text = /* bash */ ''
        profile-name=Puzzel
        # This is the default profile ID. Generate new ones with `uuidgen`.
        # The default profile-id is 38703862-805c-441c-922e-ee45eaf2bb5e
        profile-id=b1c1fb6c-0bf0-44eb-9dde-c56463b3ef27
        server-name=vpn.puzzel.com
        login-type=vpn_O365
        user-name=tobias.lindholm@puzzel.com
        keychain=true
        search-domains=prod.local,dev.local,puzzel.com
        set-routing-domains=true
        tunnel-type=ipsec
        if-name=snx-puzzel
        ike-persist=true
        ike-lifetime=604800
      '';
    };
  };
}

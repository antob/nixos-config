{ inputs, config, ... }:
let
  inherit (config.aspects) nixos;
in
{
  flake.modules.nixos.laptob =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    with lib;
    let
      wgIp = "10.64.1.7";
    in
    {
      antob = {
        systemd-networking = {
          hostName = "laptob";
          # Derived from `head -c 8 /etc/machine-id`
          hostId = "6278643e";
        };

        wireguard = {
          address = "${wgIp}/24";
        };

        clipperd = {
          bindIp = wgIp;
        };

      };

      imports = with nixos; [
        workstation
        laptop
        secure-boot
      ];

      # Framework-specific fix for the Goodix fingerprint reader which comes back
      # in a bad state after suspend/hibernate resume.
      services.udev.extraRules = mkIf config.services.fprintd.enable ''
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="27c6", ATTR{idProduct}=="609c", ATTR{authorized}="0", ATTR{authorized}="1", RUN+="${pkgs.systemd}/bin/systemctl try-restart fprintd.service"
      '';

      # Make fprintd's own startup wait until the reader is actually enumerated before it opens
      systemd.services.fprintd.serviceConfig.ExecStartPre =
        mkIf config.services.fprintd.enable "${pkgs.writeShellScript "wait-for-goodix-reader" ''
          for _ in $(seq 1 30); do
            for f in /sys/bus/usb/devices/*/idVendor; do
              dir=$(${pkgs.coreutils}/bin/dirname "$f")
              vendor=$(${pkgs.coreutils}/bin/cat "$f" 2>/dev/null)
              product=$(${pkgs.coreutils}/bin/cat "$dir/idProduct" 2>/dev/null)
              if [ "$vendor" = "27c6" ] && [ "$product" = "609c" ]; then
                exit 0
              fi
            done
            sleep 0.1
          done
          exit 0
        ''}";

      services.logind.settings.Login = {
        HandleLidSwitch = "suspend-then-hibernate";
        HandleLidSwitchExternalPower = "suspend-then-hibernate";
        HandleSuspendKey = "suspend-then-hibernate";
      };

      # Hibernate after 4h of sleep.
      systemd.sleep.settings.Sleep = {
        HibernateDelaySec = "4h";
        HibernateOnACPower = "no";
      };

      # Sops secrets
      sops.secrets.wg0_private_key.sopsFile = ./secrets.yaml;

      system.stateVersion = "22.11";
    };

  flake.nixosConfigurations.laptob = inputs.nixpkgs.lib.nixosSystem { modules = [ nixos.laptob ]; };
}

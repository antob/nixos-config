{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.antob.hardware.ucsi-reset;
in
{
  options.antob.hardware.ucsi-reset = with types; {
    enable = mkEnableOption "Whether to reload the UCSI Type-C driver after each resume to clear stale connector state.";
  };

  config = mkIf cfg.enable {
    # Workaround for a kernel bug where the UCSI controller stops honouring
    # connector-change notifications after a plug/unplug event. The ucsi_acpi
    # driver then keeps a phantom USB-C power source registered, so
    # `ucsi-source-psy-*` reports `online=1` even when nothing is connected.
    # systemd's on_ac_power() sees that stale source and, with
    # HibernateOnACPower=no, never hibernates for suspend-then-hibernate.
    # Reloading the driver around each sleep clears the phantom state.
    #
    # The unload happens in `pre`, not `post`: after resume the controller
    # times out UCSI commands (10s each), and `modprobe -r` blocks until they
    # finish. systemd-sleep keeps user.slice frozen until all post hooks
    # return, so unloading on resume froze the lock screen for 10-70s.
    # Unloading before sleep makes the post hook a fast insert only.
    environment.etc."systemd/system-sleep/ucsi-reset.sh" = {
      mode = "0755";
      text = ''
        #!/bin/sh
        case "$1" in
          pre)
            if ${pkgs.kmod}/bin/modprobe -r ucsi_acpi 2>&1 | ${pkgs.util-linux}/bin/logger -t ucsi-reset; then
              ${pkgs.util-linux}/bin/logger -t ucsi-reset "modprobe -r ucsi_acpi: ok"
            else
              ${pkgs.util-linux}/bin/logger -t ucsi-reset "modprobe -r ucsi_acpi: FAILED (module likely busy)"
            fi
            ;;
          post)
            ${pkgs.kmod}/bin/modprobe ucsi_acpi
            ${pkgs.util-linux}/bin/logger -t ucsi-reset "modprobe ucsi_acpi (insert): done"
            ;;
        esac
      '';
    };
  };
}

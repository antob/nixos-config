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
    # Reloading the driver after each resume clears the phantom state.
    environment.etc."systemd/system-sleep/ucsi-reset.sh" = {
      mode = "0755";
      text = ''
        #!/bin/sh
        case "$1" in
          post)
            case "$SYSTEMD_SLEEP_ACTION" in
              hibernate) exit 0 ;;
            esac
            if ${pkgs.kmod}/bin/modprobe -r ucsi_acpi 2>&1 | ${pkgs.util-linux}/bin/logger -t ucsi-reset; then
              ${pkgs.util-linux}/bin/logger -t ucsi-reset "modprobe -r ucsi_acpi: ok"
            else
              ${pkgs.util-linux}/bin/logger -t ucsi-reset "modprobe -r ucsi_acpi: FAILED (module likely busy)"
            fi
            ${pkgs.kmod}/bin/modprobe ucsi_acpi
            ${pkgs.util-linux}/bin/logger -t ucsi-reset "modprobe ucsi_acpi (insert): done"
            ;;
        esac
      '';
    };
  };
}

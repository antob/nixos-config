{
  flake.modules.nixos.solaar = {
    programs.solaar = {
      enable = true;
      # Re-applies saved device settings (e.g. manual keyboard backlight) on reconnect.
      userService.enable = true;
    };

    # MX Mechanical Mini mic-mute key arrives as BTN_0 (Bolt receiver or Bluetooth); map it to KEY_MICMUTE.
    services.udev.extraHwdb = ''
      evdev:input:b0003v046DpC548*
      evdev:input:b0005v046DpB367*
       KEYBOARD_KEY_100e1=micmute
    '';

    antob.persistence.home.directories = [
      ".config/solaar"
    ];
  };
}

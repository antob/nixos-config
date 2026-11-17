{
  flake.modules.nixos.solaar = {
    programs.solaar.enable = true;

    # MX Mechanical Mini mic-mute key arrives as BTN_0 via the Bolt receiver; map it to KEY_MICMUTE.
    services.udev.extraHwdb = ''
      evdev:input:b0003v046DpC548*
       KEYBOARD_KEY_100e1=micmute
    '';

    antob.persistence.home.directories = [
      ".config/solaar"
    ];
  };
}

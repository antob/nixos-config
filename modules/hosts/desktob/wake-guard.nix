{
  # Used by wake-desktob: keeps the display off and suspend blocked after a remote wake.
  flake.modules.nixos.desktob =
    { lib, pkgs, ... }:
    let
      guard = pkgs.callPackage ./_files/wake-desktob-guard.nix { };
    in
    {
      environment.systemPackages = [ guard ];

      antob = {
        # libinput debug-events reads /dev/input/event*
        user.extraGroups = [ "input" ];

        # Dedicated key for pidesk, limited to starting the guard (no YubiKey touch needed).
        # The private half is the pidesk secret desktob_wake_key.
        openssh.authorizedKeys = [
          ''restrict,command="${guard}/bin/wake-desktob-guard start" ${lib.trim (builtins.readFile ./_files/wake-desktob.pub)}''
        ];
      };
    };
}

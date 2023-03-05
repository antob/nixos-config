{
  user = import ./user.nix;

  hardware = {
    networking = import ./hardware/networking.nix;
    fingerprint = import ./hardware/fingerprint.nix;
  };

  system = {
    locale = import ./system/locale.nix;
    console = import ./system/console.nix;
  };
}

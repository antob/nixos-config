{
  flake.modules.nixos.audio =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    with lib;
    {
      config = {
        # Enable sound with pipewire.
        services.pulseaudio.enable = false;
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          wireplumber.enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          # If you want to use JACK applications, uncomment this
          #jack.enable = true;
        };

        environment.systemPackages = with pkgs; [
          pulsemixer
          pavucontrol
          pulseaudio # provides `pactl`, which is required by some apps
        ];
        antob.persistence.home.directories = [ ".local/state/wireplumber" ];
      };
    };

}

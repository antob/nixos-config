{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.hardware.audio;
in
{
  options.antob.hardware.audio = with types; {
    enable = mkEnableOption "Whether or not to enable audio support";
  };

  config = mkIf cfg.enable {
    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;

      # Supposed to fix webcam high power consumption
      wireplumber.configPackages = [
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/10-disable-webcam.conf" ''
          wireplumber.profiles = {
            main = {
              monitor.libcamera = disabled
            }
          }
        '')
      ];
    };

    environment.systemPackages = with pkgs; [
      pulsemixer
      pavucontrol
    ];
    antob.persistence.home.directories = [ ".local/state/wireplumber" ];
  };
}

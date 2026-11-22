{
  flake.modules.nixos.hyllan = {
    services.wyoming.piper.servers.home = {
      enable = true;
      voice = "sv_SE-nst-medium";
      # HA uses host networking.
      uri = "tcp://127.0.0.1:10200";
      zeroconf.enable = false;
    };

    antob.agent-access.logUnits = [ "wyoming-piper-home" ];
  };
}

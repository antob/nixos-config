{
  flake.modules.nixos.hyllan = {
    # Local text-to-speech for Home Assistant (Wyoming), used for spoken announcements on the
    # speakers. Voices are downloaded to /var/lib/wyoming/piper on first use.
    services.wyoming.piper.servers.home = {
      enable = true;
      # Default voice; HA can request others (e.g. en_US-lessac-medium) per message.
      voice = "sv_SE-nst-medium";
      # HA runs with host networking, so localhost is enough.
      uri = "tcp://127.0.0.1:10200";
      zeroconf.enable = false;
    };

    antob.agent-access.logUnits = [ "wyoming-piper-home" ];
  };
}

{ config, lib, ... }:

with lib.antob;
let
  secrets = config.sops.secrets;
  siteDomain = "ha.antob.se";
  port = 8123;
  dataDir = "/mnt/tank/services/hass";
in
{
  virtualisation.oci-containers.containers = {
    hass = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      autoStart = true;
      extraOptions = [
        "--network=host"
        "--privileged=true"
      ];
      environment = {
        TZ = "Europe/Stockholm";
      };
      volumes = [
        "${dataDir}/config:/config"
      ];
    };
  };

  services.nginx.virtualHosts = mkSslProxy siteDomain "http://127.0.0.1:${toString port}";

  # Open ports
  networking.firewall.allowedTCPPorts = [
    port # Hass GUI port
    1400 # Sonos
  ];

  system.activationScripts.hass-setup.text = ''
    mkdir -p ${dataDir}/config
    mkdir -p ${dataDir}/zigbee2mqtt
  '';

  fileSystems = {
    "${dataDir}" = {
      device = "zpool/hass";
      fsType = "zfs";
    };
  };

  # Mosquitto, MQTT broker
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        acl = [ "pattern readwrite #" ];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };

  # zigbee2mqtt
  services.zigbee2mqtt = {
    # enable = true;
    enable = false;
    dataDir = "${dataDir}/zigbee2mqtt";
    settings = {
      homeassistant = true;
      permit_join = false;
      mqtt = {
        base_topic = "zigbee2mqtt";
        server = "mqtt://localhost:1883";
      };
      serial = {
        port = "/dev/ttyUSB0";
      };
      advanced = {
        pan_id = "'!${secrets.zigbee2mqtt.path} pan_id'";
        network_key = "'!${secrets.zigbee2mqtt.path} network_key'";
      };
    };
  };

  sops.secrets.zigbee2mqtt = { };

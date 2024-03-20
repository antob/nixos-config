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

  # Open ports
  networking.firewall.allowedTCPPorts = [
    port # Hass GUI port
    1400 # Sonos
    8089 # Zigbee2MQTT frontend
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
    enable = true;
    dataDir = "${dataDir}/zigbee2mqtt";
    settings = {
      homeassistant = true;
      permit_join = false;
      mqtt = {
        base_topic = "zigbee2mqtt";
        server = "mqtt://localhost:1883";
      };
      serial = {
        port = "/dev/serial/by-id/usb-Silicon_Labs_Sonoff_Zigbee_3.0_USB_Dongle_Plus_0001-if00-port0";
      };
      advanced = {
        pan_id = 52088;
        network_key = "!${secrets."zigbee2mqtt.yaml".path} network_key";
      };
      frontend = {
        port = 8089;
        host = "0.0.0.0";
        # Optional, enables authentication, disabled by default, cleartext (no hashing required)
        # auth_token = "your-secret-token";
        # Optional, url on which the frontend can be reached, currently only used for the Home Assistant device configuration page
        url = "http://zigbee.lan";
      };
    };
  };

  services.nginx.virtualHosts = mkSslProxy siteDomain "http://127.0.0.1:${toString port}" //
    {
      "zigbee.lan" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8089";
        };
        locations."/api" = {
          proxyPass = "http://127.0.0.1:8089/api";
          proxyWebsockets = true;
        };
      };
    };

  sops.secrets."zigbee2mqtt.yaml" = {
    owner = "zigbee2mqtt";
  };
}

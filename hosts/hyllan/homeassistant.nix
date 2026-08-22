{
  config,
  lib,
  pkgs,
  ...
}:

let
  secrets = config.sops.secrets;
  subdomain = "ha";
  port = 8123;
  zigbeePort = 8089; # Port for zigbee2mqtt frontend
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
    zigbeePort # Zigbee2MQTT frontend
  ];

  systemd.tmpfiles.rules = [
    "d ${dataDir}/config 0755 root root -"
    "d ${dataDir}/zigbee2mqtt 0755 zigbee2mqtt zigbee2mqtt -"
  ];

  fileSystems = {
    "${dataDir}" = {
      device = "zpool/hass";
      fsType = "zfs";
    };
  };

  # hyllan has no bluez daemon, so nothing powers the Bluetooth adapter on at
  # boot. Bring hci0 up explicitly before the hass container starts.
  # One-shot only: do not enable services.bluetooth here,
  # the daemon would hold the management channel and break raw-socket access.
  systemd.services.bluetooth-power-on = {
    description = "Power on Bluetooth adapter before Home Assistant starts";
    before = [ "podman-hass.service" ];
    serviceConfig.ExecStart = "${pkgs.bluez}/bin/hciconfig hci0 up";
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
      homeassistant = lib.mkForce true;
      permit_join = false;
      mqtt = {
        base_topic = "zigbee2mqtt";
        server = "mqtt://localhost:1883";
      };
      serial = {
        port = "/dev/serial/by-id/usb-Silicon_Labs_Sonoff_Zigbee_3.0_USB_Dongle_Plus_0001-if00-port0";
        adapter = "zstack";
      };
      advanced = {
        pan_id = 52088;
        network_key = "!${secrets."zigbee2mqtt.yaml".path} network_key";
      };
      frontend = {
        port = zigbeePort;
        host = "127.0.0.1";
        # Optional, url on which the frontend can be reached, currently only used for the Home Assistant device configuration page
        url = "https://zigbee.antob.net";
      };
    };
  };

  services.caddy.antobProxies = {
    "${subdomain}" = {
      hostName = "127.0.0.1";
      port = port;
    };

    "zigbee" = {
      hostName = "127.0.0.1";
      port = zigbeePort;
      extraHandleConfig = ''
        basic_auth {
          admin {$ZIGBEE_ADMIN_PASSWORD}
        }
      '';
    };
  };

  sops.secrets."zigbee2mqtt.yaml" = {
    owner = "zigbee2mqtt";
  };
}

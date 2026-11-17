{
  flake.modules.nixos.hyllan =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      inherit (config.sops) secrets;
      subdomain = "ha";
      port = 8123;
      zigbeePort = 8089; # Port for zigbee2mqtt frontend
      dataDir = "/mnt/tank/services/hass";
      configDir = "${dataDir}/home-assistant";
      rfxtrxDevice = "/dev/serial/by-id/usb-RFXCOM_RFXtrx433_A120LOLF-if00-port0";

      # Integrations, areas, dashboards and automations are managed in the UI (.storage).
      # http settings are UI-only since 2026.8, so there is no http: block here.
      configuration = pkgs.writeText "configuration.yaml" ''
        default_config:

        homeassistant:
          packages: !include_dir_named packages

        automation: !include automations.yaml
        script: !include scripts.yaml
        scene: !include scenes.yaml

        recorder:
          purge_keep_days: 14
          exclude:
            entity_globs:
              - sensor.*_voltage
              - sensor.*_current
              - sensor.*_uptime
              - sensor.*_wifi_signal
      '';
    in
    {
      virtualisation.oci-containers.containers = {
        hass = {
          image = "ghcr.io/home-assistant/home-assistant:2026.11.1";
          autoStart = true;
          extraOptions = [
            "--network=host"
            "--device=${rfxtrxDevice}:/dev/ttyRFXtrx"
            # podman stop defaults to 10s, too short for the recorder to close the database.
            "--stop-timeout=90"
          ];
          # DHCP discovery and Bluetooth adapter management need raw sockets.
          capabilities = {
            NET_ADMIN = true;
            NET_RAW = true;
          };
          environment = {
            TZ = "Europe/Stockholm";
          };
          volumes = [
            "${configDir}:/config"
            "${configuration}:/config/configuration.yaml:ro"
          ];
        };
      };

      # Open ports
      networking.firewall.allowedTCPPorts = [
        port # Hass GUI port
        1400 # Sonos
      ];

      systemd.tmpfiles.rules = [
        "d ${configDir} 0755 root root -"
        "d ${configDir}/packages 0755 root root -"
        "f ${configDir}/automations.yaml 0644 root root - []"
        "f ${configDir}/scripts.yaml 0644 root root - {}"
        "f ${configDir}/scenes.yaml 0644 root root - []"
        "d ${dataDir}/zigbee2mqtt 0755 zigbee2mqtt zigbee2mqtt -"
      ];

      fileSystems = {
        "${dataDir}" = {
          device = "zpool/hass";
          fsType = "zfs";
        };
      };

      services = {
        # Mosquitto, MQTT broker. Only Home Assistant and zigbee2mqtt on this host use it.
        mosquitto = {
          enable = true;
          listeners = [
            {
              address = "127.0.0.1";
              acl = [ "pattern readwrite #" ];
              omitPasswordAuth = true;
              settings.allow_anonymous = true;
            }
          ];
        };

        # zigbee2mqtt
        zigbee2mqtt = {
          enable = true;
          dataDir = "${dataDir}/zigbee2mqtt";
          settings = {
            homeassistant = lib.mkForce true;
            permit_join = false;
            availability.enabled = true;
            mqtt = {
              base_topic = "zigbee2mqtt";
              server = "mqtt://127.0.0.1:1883";
            };
            serial = {
              port = "/dev/serial/by-id/usb-Silicon_Labs_Sonoff_Zigbee_3.0_USB_Dongle_Plus_0001-if00-port0";
              adapter = "zstack";
            };
            advanced = {
              pan_id = 52088;
              network_key = "!${secrets."zigbee2mqtt.yaml".path} network_key";
            };
            # Must be unique here (they are MQTT topics); Home Assistant shows shorter device names.
            devices = {
              "0x00158d00089368f8".friendly_name = "Garden climate sensor";
              "0x00158d0008937376".friendly_name = "Hallway climate sensor";
              "0x00158d000893696b".friendly_name = "Upstairs hall climate sensor";
              "0x00158d008b7d3df0".friendly_name = "Front door sensor";
              "0xe0798dfffee094a1".friendly_name = "Shed zigbee repeater";
              "0xe0798dfffee7e241".friendly_name = "Living room zigbee repeater";
            };
            frontend = {
              port = zigbeePort;
              host = "127.0.0.1";
              # Optional, url on which the frontend can be reached, currently only used for the Home Assistant device configuration page
              url = "https://zigbee.antob.net";
            };
          };
        };

        caddy.antobProxies = {
          "${subdomain}" = {
            hostName = "127.0.0.1";
            inherit port;
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
      };

      sops.secrets."zigbee2mqtt.yaml" = {
        owner = "zigbee2mqtt";
      };
    };
}

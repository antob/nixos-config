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

      # Root-only container queries for the agent; no arguments are passed on to podman.
      hassCtl = pkgs.writeShellApplication {
        name = "hass-ctl";
        runtimeInputs = [ config.virtualisation.podman.package ];
        text = ''
          case "''${1:-}" in
            ps) exec podman ps --all --filter name=^hass$ ;;
            inspect) exec podman inspect hass ;;
            stats) exec podman stats --no-stream hass ;;
            top) exec podman top hass ;;
            images) exec podman images ghcr.io/home-assistant/home-assistant ;;
            check-config) exec podman exec hass python3 -m homeassistant --script check_config --config /config ;;
            *)
              echo "usage: sudo hass-ctl ps|inspect|stats|top|images|check-config" >&2
              exit 2
              ;;
          esac
        '';
      };
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
          # configuration.yaml is a plain file in the config dir, so YAML changes reload without a switch.
          volumes = [ "${configDir}:/config" ];
        };
      };

      antob.agent-access = {
        units = [
          "podman-hass"
          "zigbee2mqtt"
        ];
        logUnits = [
          "podman-hass"
          "zigbee2mqtt"
          "mosquitto"
          "caddy"
        ];
        sudoPackages = [ hassCtl ];
        gitSafeDirectories = [ configDir ];
        packages = [ pkgs.dnsutils ];
      };

      # Open ports
      networking.firewall.allowedTCPPorts = [
        port # Hass GUI port
        1400 # Sonos
      ];

      systemd.tmpfiles.rules = [
        "d ${configDir} 0755 root root -"
        "z ${configDir}/configuration.yaml 0644 agent agent -"
        "d ${configDir}/packages 0755 agent agent -"
        "Z ${configDir}/packages - agent agent -"
        "d ${configDir}/.git 0755 agent agent -"
        "f ${configDir}/automations.yaml 0644 root root - []"
        "f ${configDir}/scripts.yaml 0644 root root - {}"
        "f ${configDir}/scenes.yaml 0644 root root - []"
        "d ${dataDir}/zigbee2mqtt 0700 zigbee2mqtt zigbee2mqtt -"
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

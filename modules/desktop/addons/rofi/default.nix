{ config, ... }:
let
  inherit (config.flake.lib) mkOpt;
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.rofi =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    {
      options.antob.rofi = with types; {
        launchPrefix = mkOpt types.str "" "Prefix to use to launch apps (in dmenu mode only).";
      };

      config = {
        home-manager.sharedModules = [ homeManager.rofi ];

        environment.systemPackages = with pkgs; [
          rofi
          rofimoji
        ];

      };
    };

  flake.modules.homeManager.rofi =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = osConfig.antob.rofi;
      colors = osConfig.antob.color-scheme.colors;
      cmd-launch-webapp = lib.getExe (
        pkgs.callPackage ../../_scripts/cmd-launch-webapp.nix {
          inherit (cfg) launchPrefix;
        }
      );
      userHome = "/home/${osConfig.antob.user.name}";
    in
    {
      xdg = {
        # Custom desktop entries
        desktopEntries = {
          musicAssistant = {
            name = "Music Assistant";
            icon = ./_files/icons/music-assistant.png;
            exec = "${cmd-launch-webapp} https://music.antob.net";
          };
          slack = {
            name = "Slack";
            icon = ./_files/icons/slack.png;
            exec = "${cmd-launch-webapp} https://app.slack.com/client/T029VAUMS";
          };
          teams = {
            name = "Teams";
            icon = ./_files/icons/teams.png;
            exec = "${cmd-launch-webapp} https://teams.cloud.microsoft";
          };
          telegram = {
            name = "Telegram";
            icon = ./_files/icons/telegram.png;
            exec = "${cmd-launch-webapp} https://web.telegram.org/k";
          };
          googleMeet = {
            name = "Google Meet";
            icon = ./_files/icons/meet.png;
            exec = "${cmd-launch-webapp} https://meet.google.com";
          };
          obit = {
            name = "Chromium (OBIT)";
            icon = ./_files/icons/chromium.png;
            exec = "chromium --user-data-dir=${userHome}/.config/chromium/OBIT";
          };
          puzzel = {
            name = "Chromium (Puzzel)";
            icon = ./_files/icons/chromium.png;
            exec = "chromium --user-data-dir=${userHome}/.config/chromium/Puzzel";
          };
        };

        configFile = {
          "rofi/config.rasi".text = /* rasi */ ''
            configuration {
                modes: "drun";
                show-icons: false;
                display-drun: " ";
                drun-display-format: "{name}";
            }

            @theme "default.rasi"
          '';

          # Password prompt theme
          "rofi/themes/password.rasi".text = /* rasi */ ''
            @import "default.rasi"

            mainbox {
              children: [ "inputbar" ];
            }
          '';

          # Small window theme
          "rofi/themes/sm.rasi".text = /* rasi */ ''
            @import "default.rasi"

            window {
              width: 300px;
            }
          '';

          # Large window theme
          "rofi/themes/lg.rasi".text = /* rasi */ ''
            @import "default.rasi"

            window {
              width: 750px;
            }
          '';

          # Extra large window theme
          "rofi/themes/xl.rasi".text = /* rasi */ ''
            @import "default.rasi"

            window {
              width: 900px;
            }
          '';

          # Default theme
          "rofi/themes/default.rasi".text = /* rasi */ ''
            /*****----- Global Properties -----*****/
            * {
                background:     #${colors.base01}FF;
                background-alt: #${colors.base10}FF;
                foreground:     #${colors.base06}FF;
                selected:       #${colors.base0C}FF;
                active:         #${colors.base0B}FF;
                urgent:         #${colors.base08}FF;
            }

            * {
                font: "Hack Nerd Font 14";
            }

            * {
                border-colour:               var(selected);
                handle-colour:               var(selected);
                background-colour:           var(background);
                foreground-colour:           var(foreground);
                alternate-background:        var(background-alt);
                normal-background:           var(background);
                normal-foreground:           var(foreground);
                urgent-background:           var(urgent);
                urgent-foreground:           var(background);
                active-background:           var(active);
                active-foreground:           var(background);
                selected-normal-background:  var(background-alt);
                selected-normal-foreground:  var(selected);
                selected-urgent-background:  var(active);
                selected-urgent-foreground:  var(background);
                selected-active-background:  var(urgent);
                selected-active-foreground:  var(background);
                alternate-normal-background: var(background);
                alternate-normal-foreground: var(foreground);
                alternate-urgent-background: var(urgent);
                alternate-urgent-foreground: var(background);
                alternate-active-background: var(active);
                alternate-active-foreground: var(background);
            }

            /*****----- Main Window -----*****/
            window {
                transparency:                "real";
                location:                    center;
                anchor:                      center;
                fullscreen:                  false;
                width:                       550px;
                x-offset:                    30px;
                y-offset:                    30px;

                enabled:                     true;
                margin:                      0px;
                padding:                     10px;
                border:                      2px solid;
                border-radius:               6px;
                border-color:                @border-colour;
                cursor:                      "default";
                background-color:            @background-colour;
            }

            /*****----- Main Box -----*****/
            mainbox {
                enabled:                     true;
                spacing:                     0px;
                margin:                      0px;
                padding:                     0px 12px;
                border:                      none;
                background-color:            transparent;
                children:                    [ "inputbar", "listview" ];
            }

            /*****----- Inputbar -----*****/
            inputbar {
                enabled:                     true;
                spacing:                     10px;
                margin:                      0px;
                padding:                     10px 0px;
                background-color:            transparent;
                text-color:                  @foreground-colour;
                children:                    [ "prompt", "entry" ];
            }

            prompt {
                enabled:                     true;
                padding:                     5px 0px;
                background-color:            inherit;
                text-color:                  inherit;
            }
            textbox-prompt-colon {
                enabled:                     false;
                padding:                     5px 0px;
                expand:                      false;
                background-color:            inherit;
                text-color:                  inherit;
            }
            entry {
                enabled:                     true;
                padding:                     5px 0px;
                background-color:            inherit;
                text-color:                  inherit;
                cursor:                      text;
                // placeholder:                 "Type here...";
                placeholder-color:           #585b70;
            }
            case-indicator {
                enabled:                     true;
                background-color:            inherit;
                text-color:                  inherit;
            }

            /*****----- Listview -----*****/
            listview {
                enabled:                     true;
                columns:                     1;
                lines:                       8;
                cycle:                       true;
                dynamic:                     true;
                scrollbar:                   false;
                layout:                      vertical;
                reverse:                     false;
                fixed-height:                true;
                fixed-columns:               true;

                spacing:                     0px;
                margin:                      0px;
                padding:                     4px 0px;
                border:                      0px solid;
                border-radius:               0px;
                border-color:                @border-colour;
                background-color:            transparent;
                text-color:                  @foreground-colour;
                cursor:                      "default";
            }

            /*****----- Elements -----*****/
            element {
                enabled:                     true;
                spacing:                     10px;
                margin:                      0px;
                padding:                     12px 12px;
                border:                      0px solid;
                border-radius:               0px;
                border-color:                @border-colour;
                background-color:            transparent;
                text-color:                  @foreground-colour;
                cursor:                      pointer;
            }
            element normal.normal {
                background-color:            var(normal-background);
                text-color:                  var(normal-foreground);
            }
            element normal.urgent {
                background-color:            var(urgent-background);
                text-color:                  var(urgent-foreground);
            }
            element normal.active {
                background-color:            var(active-background);
                text-color:                  var(active-foreground);
            }
            element selected.normal {
                background-color:            var(selected-normal-background);
                text-color:                  var(selected-normal-foreground);
            }
            element selected.urgent {
                background-color:            var(selected-urgent-background);
                text-color:                  var(selected-urgent-foreground);
            }
            element selected.active {
                background-color:            var(selected-active-background);
                text-color:                  var(selected-active-foreground);
            }
            element alternate.normal {
                background-color:            var(alternate-normal-background);
                text-color:                  var(alternate-normal-foreground);
            }
            element alternate.urgent {
                background-color:            var(alternate-urgent-background);
                text-color:                  var(alternate-urgent-foreground);
            }
            element alternate.active {
                background-color:            var(alternate-active-background);
                text-color:                  var(alternate-active-foreground);
            }
            element-icon {
                background-color:            transparent;
                text-color:                  inherit;
                size:                        22px;
                cursor:                      inherit;
            }
            element-text {
                background-color:            transparent;
                text-color:                  inherit;
                highlight:                   inherit;
                cursor:                      inherit;
                vertical-align:              0.5;
                horizontal-align:            0.0;
            }

            /*****----- Message -----*****/
            message {
                enabled:                     true;
                margin:                      0px;
                padding:                     0px;
                border:                      0px solid;
                border-radius:               0px;
                border-color:                @border-colour;
                background-color:            transparent;
                text-color:                  @foreground-colour;
            }
            textbox {
                padding:                     8px 10px;
                border:                      0px solid;
                border-radius:               4px;
                border-color:                @border-colour;
                background-color:            @alternate-background;
                text-color:                  @foreground-colour;
                vertical-align:              0.5;
                horizontal-align:            0.0;
                highlight:                   none;
                placeholder-color:           @foreground-colour;
                blink:                       true;
                markup:                      true;
            }
            error-message {
                padding:                     10px;
                border:                      2px solid;
                border-radius:               4px;
                border-color:                @border-colour;
                background-color:            @background-colour;
                text-color:                  @foreground-colour;
            }
          '';
        };

      };

    };

}

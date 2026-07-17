{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.features.gaming;
in
{
  options.antob.features.gaming = with types; {
    enable = mkBoolOpt false "Whether or not to enable gaming configuration.";
  };

  config = mkIf cfg.enable {

    programs = {
      steam.enable = true;
      gamemode.enable = true;
      gamescope = {
        enable = true;
        # capSysNice = true;
        args = [
          "--fullscreen"
          "--nested-width 1920"
          "--nested-height 1080"
          "--output-width 1920"
          "--output-height 1080"
          "--max-scale 1"
          "--force-grab-cursor"
          "--backend wayland"
          "--expose-wayland"
          "--adaptive-sync"
          "--nested-unfocused-refresh 30"
        ];
      };
    };

    environment.systemPackages = with pkgs; [
      mangohud
      (heroic.override {
        extraPkgs =
          pkgs': with pkgs'; [
            gamescope
            gamemode
          ];
      })
      # lutris # install lutris launcher
      # mumble # install voice-chat
      protonup-qt # GUI for installing custom Proton versions like GE_Proton
      (retroarch.withCores (
        cores: with cores; [
          vice-x64
          puae
          scummvm
          dosbox
        ]
      ))
      # teamspeak_client # install voice-chat
    ];

    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.local/share/Steam/compatibilitytools.d";
    };

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      xone.enable = true;
    };

    # Work-around for issue with capSysNice not working in gamescope.
    # See https://github.com/NixOS/nixpkgs/issues/351516
    services.ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos;
    };

    antob = {
      home.extraOptions.xdg = {
        configFile."MangoHud/MangoHud.conf".text = ''
          horizontal
        '';

        desktopEntries = {
          unrealGold = {
            name = "Unreal Gold";
            exec = "steam-run /mnt/data/Games/OldUnreal/UnrealGold/System64/unreal-bin-amd64";
            icon = "/mnt/data/Games/OldUnreal/UnrealGold/System/ConfigLogo.bmp";
            terminal = false;
            type = "Application";
            categories = [
              "Game"
            ];
          };
          ut2004 =
            let
              launch-ut2004 = pkgs.writeShellScriptBin "launch-ut2004" ''
                LD_LIBRARY_PATH=${pkgs.sdl3.lib}/lib steam-run /mnt/data/Games/OldUnreal/UT2004/System/UT2004
              '';
            in
            {
              name = "Unreal Tournament 2004";
              exec = "${launch-ut2004}/bin/launch-ut2004";
              icon = "/mnt/data/Games/OldUnreal/UT2004/Web/images/h_logo.jpg";
              terminal = false;
              type = "Application";
              categories = [
                "Game"
              ];
            };
        };
      };

      persistence.home.directories = [
        # Steam
        ".steam"
        ".local/share/Steam"

        # Heroic
        ".config/heroic"
        ".config/legendary"

        # RetroArch
        ".config/retroarch"
      ];
    };
  };
}

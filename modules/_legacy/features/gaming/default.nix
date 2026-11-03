{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.features.gaming;

  setPlatformProfile = pkgs.writeShellScript "set-platform-profile" ''
    for f in /sys/class/platform-profile/*/profile; do
      echo "$1" > "$f"
    done
  '';

  # TODO: mangoapp segfaults when GLFW 3.4 picks Wayland, which gamescope's --expose-wayland causes.
  # https://github.com/flightlessmango/MangoHud/issues/1261
  mangohudWrapped = pkgs.symlinkJoin {
    name = "mangohud-${pkgs.mangohud.version}";
    paths = [ pkgs.mangohud ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/mangoapp --unset WAYLAND_DISPLAY
    '';
  };
in
{
  options.antob.features.gaming = with types; {
    enable = mkBoolOpt false "Whether or not to enable gaming configuration.";
    display = {
      width = mkOpt (nullOr int) null "Default gamescope game and output width.";
      height = mkOpt (nullOr int) null "Default gamescope game and output height.";
      refresh = mkOpt (nullOr int) null "Default gamescope game refresh rate.";
    };
  };

  config = mkIf cfg.enable {

    programs = {
      steam = {
        enable = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
        protontricks.enable = true;
      };
      gamemode = {
        enable = true;
        settings.custom = {
          start = "${setPlatformProfile} performance";
          end = "${setPlatformProfile} balanced";
        };
      };
      gamescope = {
        enable = true;
        # capSysNice = true;
        # Without size flags gamescope defaults to 1280x720. Launch options override these per game.
        args = [
          "--fullscreen"
          "--force-grab-cursor"
          "--backend wayland"
          "--expose-wayland"
          "--adaptive-sync"
          "--nested-unfocused-refresh 30"
        ]
        ++ optionals (cfg.display.width != null) [
          "--nested-width ${toString cfg.display.width}"
          "--output-width ${toString cfg.display.width}"
        ]
        ++ optionals (cfg.display.height != null) [
          "--nested-height ${toString cfg.display.height}"
          "--output-height ${toString cfg.display.height}"
        ]
        ++ optional (cfg.display.refresh != null) "--nested-refresh ${toString cfg.display.refresh}";
      };
    };

    environment.systemPackages = with pkgs; [
      mangohudWrapped
      (heroic.override {
        extraPkgs =
          pkgs': with pkgs'; [
            gamescope
            gamemode
          ];
      })
      # lutris # install lutris launcher
      # mumble # install voice-chat
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

    boot.kernelModules = [ "ntsync" ];

    users.groups.gamemode = { };

    # Let gamemode's start/end scripts switch the platform power profile.
    services.udev.extraRules = ''
      KERNEL=="ntsync", MODE="0666"
      SUBSYSTEM=="platform-profile", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chgrp gamemode /sys%p/profile", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys%p/profile"
    '';

    hardware = {
      graphics.enable32Bit = true;
      xone.enable = true;
    };

    # Work-around for issue with capSysNice not working in gamescope.
    # See https://github.com/NixOS/nixpkgs/issues/351516
    services.ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos;
      settings.cgroup_realtime_workaround = lib.mkForce false;
    };

    antob = {
      user.extraGroups = [ "gamemode" ];

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

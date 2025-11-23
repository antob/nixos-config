{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.mango;
  gtkCfg = config.antob.desktop.addons.gtk;
  colors = config.antob.color-scheme.colors;
  # osdclient = "${pkgs.swayosd}/bin/swayosd-client --monitor ''$(niri msg -j focused-output | jq -r '.name')";
  dm-system = lib.getExe (pkgs.callPackage ../niri/scripts/dm-system.nix { });
  dm-vpn =
    if config.antob.services.networkd-vpn.enable then
      lib.getExe (pkgs.callPackage ../scripts/dm-networkd-vpn.nix { inherit config; })
    else
      lib.getExe (pkgs.callPackage ../scripts/dm-nm-vpn.nix { });
  dm-firefox-profile = lib.getExe (
    pkgs.callPackage ../scripts/dm-firefox-profile.nix { inherit config; }
  );
  # cmd-screenshot = lib.getExe (pkgs.callPackage ../scripts/cmd-screenshot.nix { });
  # cmd-annotate = lib.getExe (pkgs.callPackage ./scripts/cmd-annotate.nix { });
  # cmd-toggle-swayidle = lib.getExe (pkgs.callPackage ../scripts/cmd-toggle-swayidle.nix { });
in
{
  imports = [ inputs.mango.nixosModules.mango ];

  options.antob.desktop.mango = with types; {
    enable = mkEnableOption "Enable MangoWC.";
  };

  config = mkIf cfg.enable {
    programs.mango.enable = true;

    antob = {
      services.gammastep = enabled;
      desktop.addons = {
        gtk = enabled;
        nautilus = enabled;
        keyring = enabled;
        mako = enabled;
        swayosd = enabled;
        swayidle = enabled;
        waybar = {
          enable = true;
          enableSystemd = true;
          modulesLeft = [ "ext/workspaces" ];
          modulesRight = [
            "group/tray-expander"
            "bluetooth"
            "custom/external-ip"
            "network"
            "pulseaudio"
            "memory"
            "cpu"
            (mkIf config.antob.system.info.laptop "battery")
            "custom/networkd-vpn"
            "custom/swayidle"
            "custom/webcam"
            "clock"
          ];
          extraStyle = '''';
        };
        walker = {
          enable = true;
          runAsService = false;
          # launchPrefix = "niri msg action spawn -- ";
        };
      };

      home.extraOptions = {
        imports = [ inputs.mango.hmModules.mango ];

        wayland.windowManager.mango = {
          enable = true;
          settings = ''
            # Cursor size
            env=XCURSOR_SIZE,16
            env=HYPRCURSOR_SIZE,16

            # Force all apps to use Wayland
            env=GDK_BACKEND,wayland,x11,*
            env=QT_QPA_PLATFORM,wayland;xcb
            env=QT_STYLE_OVERRIDE,kvantum
            env=SDL_VIDEODRIVER,wayland
            env=MOZ_ENABLE_WAYLAND,1
            env=ELECTRON_OZONE_PLATFORM_HINT,wayland
            env=OZONE_PLATFORM,wayland

            # Keybindings
            bind=Super,Return,spawn,${
              if config.antob.cli-apps.tmux.enable then "alacritty -e tmux-attach-unused" else "alacritty"
            }
            bind=Super+Shift,Return,spawn,alacritty
            bind=Super,w,spawn,firefox
            bind=Super+Shift,w,spawn,${dm-firefox-profile}
            bind=Super,e,spawn,nautilus --new-window
            bind=Super,b,spawn,alacritty --class=TUI.float -e bluetui
            bind=Super,t,spawn,alacritty --class=TUI.float.lg -e ${lib.getExe pkgs.bottom}
            bind=Super,d,spawn,walker -p 'Start…'
            bind=Super,x,spawn,${dm-system}
            bind=Super,p,spawn,${dm-vpn}
            bind=Super+Ctrl,e,spawn,walker -m Emojis

            bind=SUPER,q,killclient
            bind=SUPER+SHIFT,r,reload_config
            bind=SUPER,f,togglefullscreen
            bind=SUPER+Shift,f,togglefakefullscreen
            bind=SUPER,m,togglemaximizescreen

            bind=SUPER,o,toggleoverlay

            bind=SUPER,1,comboview,1
            bind=SUPER,2,comboview,2
            bind=SUPER,3,comboview,3
            bind=SUPER,4,comboview,4
            bind=SUPER,5,comboview,5
            bind=SUPER,6,comboview,6
            bind=SUPER,7,comboview,7
            bind=SUPER,8,comboview,8
            bind=SUPER,9,comboview,9

            # smartmovewin
            bind=CTRL+SHIFT,Up,smartmovewin,up
            bind=CTRL+SHIFT,Down,smartmovewin,down
            bind=CTRL+SHIFT,Left,smartmovewin,left
            bind=CTRL+SHIFT,Right,smartmovewin,right

            # switch window focus
            bind=SUPER,Down,focusstack,next
            bind=SUPER,Up,focusstack,prev
            bind=SUPER,Left,focusdir,left
            bind=SUPER,Right,focusdir,right

            # swap window
            bind=SUPER+SHIFT,Up,exchange_client,up
            bind=SUPER+SHIFT,Down,exchange_client,down
            bind=SUPER+SHIFT,Left,exchange_client,left
            bind=SUPER+SHIFT,Right,exchange_client,right

            # Layouts
            bind=SUPER+Ctrl,t,setlayout,tile
            bind=SUPER+Ctrl,v,setlayout,vertical_grid
            bind=SUPER+Ctrl,c,setlayout,spiral
            bind=SUPER+Ctrl,s,setlayout,scroller
            bind=SUPER+Ctrl,n,switch_layout

            # Layouts in mango are per tag. So we'll set all tags to tile by default. 
            tagrule=id:1,layout_name:tile
            tagrule=id:2,layout_name:tile
            tagrule=id:3,layout_name:tile
            tagrule=id:4,layout_name:tile
            tagrule=id:5,layout_name:tile
            tagrule=id:6,layout_name:tile
            tagrule=id:7,layout_name:tile
            tagrule=id:8,layout_name:tile
            tagrule=id:9,layout_name:tile

            animations=1
            gappih=5
            gappiv=5
            gappoh=5
            gappov=5
            borderpx=4
            no_border_when_single=0
            focuscolor=0x${colors.base0C}ff

            # Options
            repeat_rate=40
            repeat_delay=200

            # Effect
            blur=0
            blur_layer=1
            blur_optimized=1
            blur_params_num_passes = 2
            blur_params_radius = 5
            blur_params_noise = 0.02
            blur_params_brightness = 0.9
            blur_params_contrast = 0.9
            blur_params_saturation = 1.2

            shadows = 1
            layer_shadows = 1
            shadow_only_floating=1
            shadows_size = 12
            shadows_blur = 15
            shadows_position_x = 0
            shadows_position_y = 0
            shadowscolor= 0x000000ff

            # Animation Configuration
            animations=1
            layer_animations=1
            animation_type_open=zoom
            animation_type_close=slide 
            layer_animation_type_open=slide
            layer_animation_type_close=slide 
            animation_fade_in=1
            animation_fade_out=1
            tag_animation_direction=1
            zoom_initial_ratio=0.3
            zoom_end_ratio=0.7
            fadein_begin_opacity=0.6
            fadeout_begin_opacity=0.8
            animation_duration_move=500
            animation_duration_open=400
            animation_duration_tag=350
            animation_duration_close=800
            animation_curve_open=0.46,1.0,0.29,1.1
            animation_curve_move=0.46,1.0,0.29,1
            animation_curve_tag=0.46,1.0,0.29,1
            animation_curve_close=0.08,0.92,0,1

            # Scroller Layout Setting
            scroller_structs=20
            scroller_default_proportion=0.8
            scroller_focus_center=0
            scroller_prefer_center=1
            edge_scroller_pointer_focus=1
            scroller_default_proportion_single=1.0
            scroller_proportion_preset=0.5,0.8,1.0


            monitorrule=eDP-1,0.55,1,tile,0,1.5,0,0,2256,1504,60
            monitorrule=DP-1,0.55,1,tile,0,1,0,0,2560,1440,165

            xkb_rules_layout=se,se
            xkb_rules_variant=us,
            xkb_rules_options=caps:ctrl_modifier

          '';
          autostart_sh = ''
            ${pkgs.swaybg}/bin/swaybg -i ~/Pictures/Wallpapers/Omarchy-Backgrounds/1-scenery-pink-lakeside-sunset-lake-landscape-scenic-panorama-7680x3215-144.png -m fill
            ${pkgs.wl-clip-persist}/bin/wl-clip-persist --reconnect-tries 0 &
            ${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store & 
            walker --gapplication-service &
          '';
        };

        dconf.settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = gtkCfg.theme.name;
            cursor-theme = gtkCfg.cursor.name;
            cursor-size = gtkCfg.cursor.size;
          };
        };
      };

      system.env = {
        # ELECTRON_OZONE_PLATFORM_HINT = "wayland";
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORMTHEME = "qt6ct";
        # QT_QPA_PLATFORM = "wayland;xcb";
        # QT_STYLE_OVERRIDE = "kvantum";
        # SDL_VIDEODRIVER = "wayland";
        # MOZ_ENABLE_WAYLAND = "1";
        # OZONE_PLATFORM = "wayland";
      };
    };

    # [preferred]
    # default=gtk
    # org.freedesktop.impl.portal.ScreenCast=wlr
    # org.freedesktop.impl.portal.Screenshot=wlr
    # org.freedesktop.impl.portal.Secret=gnome-keyring
    # org.freedesktop.impl.portal.Inhibit=none

    # Desktop portal
    xdg.portal = {
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
      config.common = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        "org.freedesktop.impl.portal.Inhibit" = [ "none" ];
      };
    };

    # security.polkit.enable = true;

    environment.systemPackages = with pkgs; [
      gnome-keyring
      gnome-calculator
      imv
      mpv
      sushi
      brightnessctl
      swayosd
      jq
      impala
      bluetui
      wiremix
      pamixer
      swaybg
      wayland-utils
      wl-clipboard
      libqalculate
      wlr-randr
    ];

    services.displayManager = {
      autoLogin = {
        enable = config.antob.user.autoLogin;
        user = config.antob.user.name;
      };
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };
  };
}

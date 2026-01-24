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
  lockScreen = config.antob.desktop.addons.swayidle.lockScreen;
  osdclient = "${pkgs.swayosd}/bin/swayosd-client";
  dm-system = lib.getExe (pkgs.callPackage ../scripts/dm-system.nix { inherit config; });
  dm-vpn =
    if config.antob.services.networkd-vpn.enable then
      lib.getExe (pkgs.callPackage ../scripts/dm-networkd-vpn.nix { inherit config; })
    else
      lib.getExe (pkgs.callPackage ../scripts/dm-nm-vpn.nix { });
  dm-firefox-profile = lib.getExe (
    pkgs.callPackage ../scripts/dm-firefox-profile.nix { inherit config; }
  );
  cmd-screenshot = lib.getExe (pkgs.callPackage ../scripts/cmd-screenshot.nix { });
  cmd-toggle-swayidle = lib.getExe (pkgs.callPackage ../scripts/cmd-toggle-swayidle.nix { });
  cmd-launch-blankscreen = lib.getExe (pkgs.callPackage ../scripts/cmd-launch-blankscreen.nix { });
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
          extraStyle = "";
        };
        walker = {
          enable = true;
          runAsService = false;
        };
      };

      persistence.home.directories = [
        ".config/way-displays"
      ];
      # Add yourself to the input group to monitor events from way-displays
      user.extraGroups = [ "input" ];

      home.extraOptions = {
        imports = [ inputs.mango.hmModules.mango ];

        wayland.windowManager.mango = {
          enable = true;
          settings = ''
            ## Keybindings
            bind=Super,Return,spawn,${
              if config.antob.cli-apps.tmux.enable then "alacritty -e tmux-attach-unused" else "alacritty"
            }
            bind=Super+Shift,Return,spawn,alacritty
            bind=Super,w,spawn,firefox
            bind=Super+Shift,w,spawn,${dm-firefox-profile}
            bind=Super,e,spawn,nautilus --new-window
            bind=Super,b,spawn,alacritty --class=TUI.float -e bluetui
            bind=Super,n,spawn,alacritty --class=TUI.float.lg -e ${pkgs.impala}/bin/impala
            bind=Super,t,spawn,alacritty --class=TUI.float.lg -e ${lib.getExe pkgs.bottom}
            bind=Super,d,spawn,walker -p 'Start…'
            bind=Super,x,spawn,${dm-system}
            bind=Super,p,spawn,${dm-vpn}
            bind=Super+Ctrl,e,spawn,walker -m Emojis
            bind=None,Print,spawn,${cmd-screenshot}
            bind=Super,u,spawn,${cmd-toggle-swayidle}
            bind=Super,l,spawn_shell,${
              if lockScreen then
                "loginctl lock-session && ${pkgs.wlr-dpms}/bin/wlr-dpms off"
              else
                "${cmd-launch-blankscreen}"
            }
            bind=Super+Ctrl,b,toggle_render_border
            bind=Super+Ctrl,g,togglegaps

            # Brightness controls
            bind=NONE,XF86MonBrightnessUp,spawn,${osdclient} --brightness raise
            bind=NONE,XF86MonBrightnessDown,spawn,${osdclient} --brightness lower
            bind=ALT,XF86MonBrightnessUp,spawn,${osdclient} --brightness +1
            bind=ALT,XF86MonBrightnessDown,spawn,${osdclient} --brightness -1

            # Volume controls
            bind=NONE,XF86AudioRaiseVolume,spawn,${osdclient} --output-volume raise
            bind=NONE,XF86AudioLowerVolume,spawn,${osdclient} --output-volume lower
            bind=ALT,XF86AudioRaiseVolume,spawn,${osdclient} --output-volume +1
            bind=ALT,XF86AudioLowerVolume,spawn,${osdclient} --output-volume -1
            bind=NONE,XF86AudioMute,spawn,${osdclient} --output-volume mute-toggle
            bind=NONE,XF86AudioMicMute,spawn,${osdclient} --input-volume mute-toggle";

            bind=SUPER,q,killclient
            bind=SUPER+SHIFT,r,reload_config
            bind=SUPER,f,togglefullscreen
            bind=SUPER+Shift,f,togglefakefullscreen
            bind=SUPER,m,togglemaximizescreen
            bind=SUPER,v,togglefloating
            bind=SUPER,o,toggleoverview

            # switch workspace
            bind=SUPER,1,comboview,1
            bind=SUPER,2,comboview,2
            bind=SUPER,3,comboview,3
            bind=SUPER,4,comboview,4
            bind=SUPER,5,comboview,5
            bind=SUPER,6,comboview,6
            bind=SUPER,7,comboview,7
            bind=SUPER,8,comboview,8
            bind=SUPER,9,comboview,9

            # move window to workspace
            bind=SUPER+Shift,1,tag,1,0
            bind=SUPER+Shift,2,tag,2,0
            bind=SUPER+Shift,3,tag,3,0
            bind=SUPER+Shift,4,tag,4,0
            bind=SUPER+Shift,5,tag,5,0
            bind=SUPER+Shift,6,tag,6,0
            bind=SUPER+Shift,7,tag,7,0
            bind=SUPER+Shift,8,tag,8,0
            bind=SUPER+Shift,9,tag,9,0

            # switch window focus
            bind=SUPER,Right,focusstack,next
            bind=SUPER,Left,focusstack,prev
            bind=SUPER,Up,focusdir,up
            bind=SUPER,Down,focusdir,down

            # switch monitor focus
            bind=ALT+SUPER,Down,focusmon,down
            bind=ALT+SUPER,Up,focusmon,up
            bind=ALT+SUPER,Left,focusmon,left
            bind=ALT+SUPER,Right,focusmon,right

            # move window to monitor
            bind=ALT+SUPER+SHIFT,Down,tagmon,down,1
            bind=ALT+SUPER+SHIFT,Up,tagmon,up,1
            bind=ALT+SUPER+SHIFT,Left,tagmon,left,1
            bind=ALT+SUPER+SHIFT,Right,tagmon,right,1

            # swap window
            bind=SUPER+SHIFT,Up,exchange_client,up
            bind=SUPER+SHIFT,Down,exchange_client,down
            bind=SUPER+SHIFT,Left,exchange_client,left
            bind=SUPER+SHIFT,Right,exchange_client,right

            # resize window
            # Super+Minus
            bind=SUPER,code:20,switch_proportion_preset
            # Super+Shift+Plus
            bind=SUPER+SHIFT,code:21,resizewin,100
            # Super+Shift+Minus
            bind=SUPER+SHIFT,code:20,resizewin,-100
            # Super+Ctrl+Plus
            bind=SUPER+CTRL,code:21,resizewin,0,100
            # Super+Ctrl+Minus
            bind=SUPER+CTRL,code:20,resizewin,0,-100

            # Layouts
            bind=SUPER+Ctrl,t,setlayout,tile
            bind=SUPER+Ctrl,m,setlayout,monocle
            bind=SUPER+Ctrl,s,setlayout,scroller
            bind=SUPER+Ctrl,n,switch_layout

            ## Mouse Bindings
            mousebind=SUPER,btn_left,moveresize,curmove
            mousebind=SUPER,btn_right,moveresize,curresize
            mousebind=NONE,btn_left,toggleoverview,1
            mousebind=NONE,btn_right,killclient,0

            ## Env settings
            env=XCURSOR_SIZE,${toString gtkCfg.cursor.size}

            # Force all apps to use Wayland
            env=GDK_BACKEND,wayland,x11,*
            env=QT_QPA_PLATFORM,wayland;xcb
            env=QT_STYLE_OVERRIDE,kvantum
            env=SDL_VIDEODRIVER,wayland
            env=MOZ_ENABLE_WAYLAND,1
            env=ELECTRON_OZONE_PLATFORM_HINT,wayland
            env=OZONE_PLATFORM,wayland

            ## Window Effects Configuration
            blur=0
            blur_layer=1
            blur_optimized=1
            blur_params_num_passes = 2
            blur_params_radius = 5
            blur_params_noise = 0.02
            blur_params_brightness = 0.9
            blur_params_contrast = 0.9
            blur_params_saturation = 1.2
            shadows = 0
            # layer_shadows = 1
            # shadow_only_floating=1
            # shadows_size = 12
            # shadows_blur = 15
            # shadows_position_x = 0
            # shadows_position_y = 0
            # shadowscolor= 0x000000ff
            border_radius=6

            ## Animation Configuration
            animations=1
            layer_animations=1
            animation_type_open=fade
            animation_type_close=fade
            layer_animation_type_open=fade
            layer_animation_type_close=fade
            animation_fade_in=1
            animation_fade_out=1
            tag_animation_direction=1
            # zoom_initial_ratio=0.3
            # zoom_end_ratio=0.7
            fadein_begin_opacity=0.5
            fadeout_begin_opacity=0.8
            animation_duration_move=400
            animation_duration_open=100
            animation_duration_tag=0
            animation_duration_close=100
            # animation_curve_open=0.46,1.0,0.29,1.1
            # animation_curve_move=0.46,1.0,0.29,1
            # animation_curve_tag=0.46,1.0,0.29,1
            # animation_curve_close=0.08,0.92,0,1

            ## Scroller Layout Setting
            scroller_structs=20
            scroller_default_proportion=0.9
            scroller_focus_center=1
            scroller_prefer_center=1
            edge_scroller_pointer_focus=0
            scroller_default_proportion_single=1.0
            scroller_proportion_preset=0.75,0.5,0.25,1.0

            ## Master-Stack Layout Settings
            new_is_master=0

            ## Overview Settings
            enable_hotarea=0

            ## Miscellaneous Settings
            cursor_size=${toString gtkCfg.cursor.size}
            cursor_theme=${gtkCfg.cursor.name}
            cursor_hide_timeout=5

            ## Keyboard Settings
            repeat_rate=40
            repeat_delay=200

            ## Trackpad Settings & Mouse Settings
            tap_to_click=1
            disable_while_typing=1
            trackpad_natural_scrolling=1

            ## Appearance Settings
            gappih=10
            gappiv=10
            gappoh=10
            gappov=10
            borderpx=3
            no_border_when_single=1
            bordercolor=0x${colors.base12}ff
            focuscolor=0x${colors.base0C}ff
            maximizescreencolor=0x${colors.base12}ff
            urgentcolor=0x${colors.base08}ff
            scratchpadcolor=0x${colors.base12}ff
            globalcolor=0x${colors.base12}ff
            overlaycolor=0x${colors.base12}ff

            ## Tag Rules
            tagrule=id:1,no_hide:1,layout_name:scroller
            tagrule=id:2,no_hide:1,layout_name:monocle,no_render_border:1
            tagrule=id:3,no_hide:1,layout_name:scroller
            tagrule=id:4,no_hide:1,layout_name:scroller
            tagrule=id:5,no_hide:1,layout_name:scroller
            tagrule=id:6,no_hide:1,layout_name:scroller
            tagrule=id:7,no_hide:1,layout_name:scroller
            tagrule=id:8,no_hide:1,layout_name:scroller
            tagrule=id:9,no_hide:1,layout_name:scroller

            ## Window Rules
            # Floating windows
            windowrule=isfloating:1,width:1100,height:700,appid:^TUI.float.lg$
            windowrule=isfloating:1,appid:^TUI.float$
            windowrule=isfloating:1,appid:Wiremix
            windowrule=isfloating:1,title:satty|Copy color to Clipboard
            windowrule=isfloating:1,title:Bluetooth Devices|blueman
            windowrule=isfloating:1,appid:firefox,title:^Extension.*$
            windowrule=isfloating:1,appid:X64

            # Windows on specific workspace
            windowrule=tags:2,appid:firefox
            windowrule=tags:3,appid:code
            windowrule=tags:5,appid:obsidian|chrome-app.slack.com|chrome-teams.microsoft.com|chrome-meet.google.com|chrome-music.antob.net

            # Transparancy
            windowrule=focused_opacity:1.0,unfocused_opacity:1.0,appid:Alacritty

            # Screensaver
            windowrule=isfullscreen:1,focused_opacity:1.0,unfocused_opacity:1.0,appid:Screensaver,title:Alacritty

            ## Monitor Rules
            # monitorrule=name,mfact,nmaster,layout,transform,scale,x,y,width,height,refreshrate
            # Internal laptop screen
            #monitorrule=eDP-1,0.55,1,scroller,0,1.5,1808,1440,2256,1504,60
            # Home monitor
            #monitorrule=Acer Technologies XB273U TJ5EE0018521,0.55,1,scroller,0,1.5,1280,0,2560,1440,165
            # OBIT monitor 1
            #monitorrule=Philips Consumer Electronics Company PHL 49B2U5900 AU02507007832,0.55,1,scroller,0,1,0,0,5120,1440,60
            # OBIT monitor 1
            #monitorrule=LG Electronics LG HDR DQHD 0x000320C3,0.55,1,scroller,0,1,0,0,5120,1440,60

            ## Keyboard layout and IME
            xkb_rules_layout=se,se
            xkb_rules_variant=us,
            xkb_rules_options=caps:ctrl_modifier

            ## Exec setting
            exec-once=~/.config/mango/autostart.sh
            exec-once=way-displays > /tmp/way-displays.log 2>&1
            exec-once=${pkgs.sway-audio-idle-inhibit}/bin/sway-audio-idle-inhibit
            exec-once=walker --gapplication-service
            exec-once=${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular --reconnect-tries 0
            exec-once=${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store 
          '';
          autostart_sh = ''
            # This needs to be non-empty for mango flake to add needed commands.
            ${pkgs.swaybg}/bin/swaybg -i ~/Pictures/Wallpapers/Omarchy-Backgrounds/1-scenery-pink-lakeside-sunset-lake-landscape-scenic-panorama-7680x3215-144.png -m fill
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

    environment.systemPackages =
      with pkgs;
      [
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
        way-displays
        wlr-dpms
      ]
      # Custom scripts
      ++ (import ./scripts { inherit pkgs; });

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

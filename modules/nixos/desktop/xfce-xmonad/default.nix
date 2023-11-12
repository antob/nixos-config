{ config, lib, pkgs, ... }:

with lib;
with lib.antob;
let
  cfg = config.antob.desktop.xfce-xmonad;
  gtkCfg = config.antob.desktop.addons.gtk;

  dm-logout = pkgs.callPackage ./scripts/dm-logout.nix { };
  dm-vpn = pkgs.callPackage ./scripts/dm-vpn.nix { };
  dm-librewolf-profile =
    pkgs.callPackage ./scripts/dm-librewolf-profile.nix { };
  toggle-kbd-variant = pkgs.callPackage ./scripts/toggle-kbd-variant.nix { };

in
{
  options.antob.desktop.xfce-xmonad = with types; {
    enable = mkEnableOption "Enable XMonad window manager.";
    dpi = mkOpt int 120 "DPI to add to xrdb.";
    mainDisplay = mkOpt types.str "eDP-1" "The name of the main display.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      xmonad-log
      xfce.thunar-volman
      feh
      dmenu
      j4-dmenu-desktop
      gnome.gnome-calculator
      xcwd
      xdotool
      xclip
    ];

    antob.persistence.home.directories = [{
      directory = ".config/xfce4";
      method = "symlink";
    }];

    # Desktop additions
    antob.desktop.addons = {
      gtk = enabled;
      keyring = enabled;
      polybar = {
        enable = true;
        trayOutput = cfg.mainDisplay;
      };
      volumeicon = enabled;
      udisks2 = enabled;
      autorandr = enabled;
      yubikey-touch-detector = enabled;
    };

    # Services
    services.redshift = enabled;

    # Desktop portal
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    # dconf and xfconf settings
    antob.home.extraOptions = {
      xsession.enable = true;

      xfconf = {
        enable = true;
        settings = {
          keyboards = {
            "Default/KeyRepeat/Delay" = 200;
            "Default/KeyRepeat/Rate" = 40;
          };

          xsettings = {
            "Gtk/CursorThemeName" = gtkCfg.cursor.name;
            "Gtk/CursorThemeSize" = gtkCfg.cursor.size;
            "Net/ThemeName" = gtkCfg.theme.name;
          };

          xfce4-power-manager = {
            "xfce4-power-manager/show-tray-icon" = true;
            "xfce4-power-manager/brightness-switch" = 0;
            "xfce4-power-manager/brightness-switch-restore-on-exit" = 1;
            "xfce4-power-manager/handle-brightness-keys" = true;
            "xfce4-power-manager/lid-action-on-battery" = 3;
            "xfce4-power-manager/logind-handle-lid-switch" = true;
            "xfce4-power-manager/critical-power-action" = 0;
            "xfce4-power-manager/lid-action-on-ac" = 1;
          };

          xfce4-desktop = {
            "backdrop/screen0/monitoreDP-1/workspace0/color-style" = 0;
            "backdrop/screen0/monitoreDP-1/workspace0/image-style" = 5;
            # "backdrop/screen0/monitoreDP-1/workspace0/last-image" = lockBackground;
          };

          xfce4-notifyd = {
            "notify-location" = 3;
          };

          xfce4-session = {
            "compat/LaunchGNOME" = true;
          };

          # displays = {
          #   "ActiveProfile" = "Default";
          #   "Default/Virtual-1" = "Virtual-1";
          #   "Default/Virtual-1/Active" = true;
          #   "Default/Virtual-1/Resolution" = "2560x1600";
          #   "Default/Virtual-1/RefreshRate" = "59.98658779075852";
          #   "Default/Virtual-1/Primary" = true;
          #   "Default/Virtual-1/Scale/X" = 1.0;
          #   "Default/Virtual-1/Scale/Y" = 1.0;
          #   "Default/Virtual-1/Position/X" = 0;
          #   "Default/Virtual-1/Position/Y" = 0;
          #   "Default/Virtual-1/Rotation" = 0;
          #   "Default/Virtual-1/Reflection" = 0;
          # };
        };
      };

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = gtkCfg.theme.name;
          cursor-theme = gtkCfg.cursor.name;
          cursor-size = gtkCfg.cursor.size;
        };
        "org/gnome/nm-applet" = {
          disable-connected-notifications = true;
          disable-disconnected-notifications = true;
        };
      };
    };

    services.xbanish.enable = true;

    services.xserver = {
      # Enable the X11 windowing system.
      enable = true;

      # Configure keymap in X11
      layout = "se,se";
      xkbVariant = "us,";
      xkbOptions = "caps:ctrl_modifier,grp:win_space_toggle";

      # Configure Set console typematic delay and rate in X11
      autoRepeatDelay = 200;
      autoRepeatInterval = 40;

      libinput = {
        enable = true;
        touchpad = {
          disableWhileTyping = true;
          naturalScrolling = true;
        };
      };

      # Enable LightDm display manager.
      displayManager = {
        lightdm = {
          enable = true;
          # background = lockBackground;
        };
        defaultSession = "xfce+xmonad";
        autoLogin = mkIf config.antob.user.autoLogin {
          enable = true;
          user = config.antob.user.name;
        };
        sessionCommands = ''
          ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
            Xft.dpi: ${builtins.toString cfg.dpi}
          EOF
        '';
      };

      # Enable the XFCE Desktop Environment.
      desktopManager.xfce = {
        enable = true;
        noDesktop = true;
        enableXfwm = false;
      };

      windowManager = {
        xmonad = {
          enable = true;
          enableContribAndExtras = true;
          extraPackages = haskellPackages: [ haskellPackages.xmonad-dbus ];
          # config = ./xmonad.hs;
          config = ''
              -- Base
            import XMonad
            import qualified XMonad.StackSet as W
            import Control.Monad (join)

                -- Actions
            import XMonad.Actions.CopyWindow (kill1)
            import XMonad.Actions.CycleSelectedLayouts (cycleThroughLayouts)
            import XMonad.Actions.CycleWS (Direction1D(..), moveTo, shiftTo, WSType(..), nextScreen, prevScreen, toggleWS)
            import XMonad.Actions.Promote
            import XMonad.Actions.RotSlaves (rotSlavesDown, rotAllDown)
            import XMonad.Actions.WithAll (killAll)

                -- Data
            import Data.Monoid
            import Data.Maybe (isJust, maybeToList)
            import Data.List
            import qualified Data.Map as M

                -- Hooks
            import XMonad.Hooks.DynamicLog (dynamicLogWithPP, wrap, shorten)
            import XMonad.Hooks.EwmhDesktops
            import XMonad.Hooks.ManageDocks (avoidStruts, docks, manageDocks, ToggleStruts(..))
            import XMonad.Hooks.ManageHelpers (isDialog, isFullscreen, doFullFloat, doCenterFloat)
            import XMonad.Hooks.SetWMName
            import XMonad.Hooks.StatusBar.PP
            import XMonad.Hooks.WindowSwallowing

                -- Layouts
            import XMonad.Layout.ResizableTile
            import XMonad.Layout.ThreeColumns
            import XMonad.Layout.PerWorkspace

                -- Layouts modifiers
            import XMonad.Layout.LayoutModifier
            import XMonad.Layout.LimitWindows (limitWindows, increaseLimit, decreaseLimit)
            import XMonad.Layout.MultiToggle (mkToggle, EOT(EOT), (??))
            import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL, MIRROR, NOBORDERS))
            import XMonad.Layout.NoBorders
            import XMonad.Layout.Renamed
            import XMonad.Layout.Spacing
            import XMonad.Layout.WindowArranger (windowArrange, WindowArrangerMsg(..))
            import qualified XMonad.Layout.MultiToggle as MT (Toggle(..))

               -- Utilities
            import XMonad.Util.EZConfig (additionalKeysP)
            import XMonad.Util.Hacks (windowedFullscreenFixEventHook)
            import XMonad.Util.NamedScratchpad
            import XMonad.Util.Run (spawnPipe)
            import XMonad.Util.SpawnOnce
            import qualified Codec.Binary.UTF8.String as UTF8

               -- dbus
            import qualified DBus as D
            import qualified DBus.Client as D

            -- Color theme
            -- base16 - OneDark
            base00Color = "#282c34"
            base01Color = "#353b45"
            base02Color = "#3e4451"
            base03Color = "#545862"
            base04Color = "#565c64"
            base05Color = "#ebdbb2" -- orgiginal base05Color is #abb2bf
            base06Color = "#b6bdca"
            base07Color = "#c8ccd4"
            base08Color = "#be5046"
            base09Color = "#d19a66"
            base0AColor = "#e5c07b"
            base0BColor = "#98c379"
            base0CColor = "#56b6c2"
            base0DColor = "#61afef"
            base0EColor = "#e06c75"
            base0FColor = "#be5046"

            -- Settings
            myFont :: String
            myFont = "xft:SauceCodePro Nerd Font Mono:regular:size=9:antialias=true:hinting=true"

            myModMask :: KeyMask
            myModMask = mod4Mask        -- Sets modkey to super/windows key

            myTerminal :: String
            -- myTerminal = "alacritty --working-directory `xcwd`"    -- Sets default terminal
            myTerminal = "kitty --working-directory `xcwd`"    -- Sets default terminal

            myBrowser :: String
            myBrowser = "librewolf "    -- Sets librewolf as browser

            myBorderWidth :: Dimension
            myBorderWidth = 3           -- Border width for windows

            myNormColor :: String
            myNormColor   = base01Color -- Border color of normal windows

            myFocusColor :: String
            myFocusColor  = base0CColor -- Border color of focused windows

            main :: IO ()
            main = do
              dbus <- D.connectSession
              D.requestName dbus (D.busName_ "org.xmonad.Log")
                  [D.nameAllowReplacement, D.nameReplaceExisting, D.nameDoNotQueue]
              xmonad $ docks $ ewmhFullscreen $ ewmh $ def
                { manageHook         = myManageHook <+> namedScratchpadManageHook myScratchPads <+> manageDocks
                , handleEventHook    = windowedFullscreenFixEventHook <> swallowEventHook (className =? "Alacritty"  <||> className =? "st-256color" <||> className =? "XTerm") (return True)
                , modMask            = myModMask
                , terminal           = myTerminal
                , startupHook        = myStartupHook <+> setFullscreenSupported
                , layoutHook         = myLayoutHook
                , workspaces         = myWorkspaces
                , borderWidth        = myBorderWidth
                , normalBorderColor  = myNormColor
                , focusedBorderColor = myFocusColor
                , logHook            = dynamicLogWithPP $ filterOutWsPP [scratchpadWorkspaceTag] (myLogHook dbus)
                } `additionalKeysP` myKeys

            -- Hooks
            myStartupHook :: X ()
            myStartupHook = do
              spawn "${pkgs.xorg.xsetroot}/bin/xsetroot -cursor_name left_ptr"
              spawn "~/.fehbg"
              setWMName "LG3D"

            myScratchPads :: [NamedScratchpad]
            myScratchPads = [ NS "terminal" spawnTerm findTerm manageTerm
                            , NS "calculator" spawnCalc findCalc manageCalc
                            ]
              where
                spawnTerm  = myTerminal ++ " -t scratchpad"
                findTerm   = title =? "scratchpad"
                manageTerm = customFloating $ W.RationalRect l t w h
                           where
                             h = 0.9
                             w = 0.9
                             t = 0.95 -h
                             l = 0.95 -w
                spawnCalc  = "gnome-calculator"
                findCalc   = className =? "gnome-calculator"
                manageCalc = customFloating $ W.RationalRect l t w h
                           where
                             h = 0.5
                             w = 0.4
                             t = 0.75 -h
                             l = 0.70 -w

            -- The layout hook
            myLayoutHook = avoidStruts $ smartBorders $ mkToggle (NBFULL ?? NOBORDERS ?? EOT)
                $ onWorkspaces [myWorkspaces !! 1, myWorkspaces !! 2, myWorkspaces !! 4] layoutMonocleDefault
                $ layoutTallDefault
              where
                tall     = renamed [Replace "tall"]
                          $ limitWindows 5
                          $ mySpacing 8
                          $ ResizableTall 1 (3/100) (1/2) []
                monocle  = renamed [Replace "monocle"]
                          $ noBorders
                          $ Full
                threeCol = renamed [Replace "threeCol"]
                          $ limitWindows 7
                          $ mySpacing 8
                          $ ThreeCol 1 (3/100) (1/2)
                threeRow = renamed [Replace "threeRow"]
                          $ limitWindows 7
                          $ mySpacing 8
                          $ Mirror
                          $ ThreeCol 1 (3/100) (1/2)

                layoutMonocleDefault = monocle ||| tall ||| threeCol ||| threeRow
                layoutTallDefault = tall ||| monocle ||| threeCol ||| threeRow

            myWorkspaces = [" 1 ", " 2 ", " 3 ", " 4 ", " 5 ", " 6 ", " 7 ", " 8 ", " 9 "]
            myWorkspaceIndices = M.fromList $ zipWith (,) myWorkspaces [1..] -- (,) == \x y -> (x,y)

            myManageHook :: XMonad.Query (Data.Monoid.Endo WindowSet)
            myManageHook = composeAll
              [ isDialog --> doFloatNoBorder
              , className =? "confirm"         --> doFloatNoBorder
              , className =? "file_progress"   --> doFloatNoBorder
              , className =? "dialog"          --> doFloatNoBorder
              , className =? "download"        --> doFloatNoBorder
              , className =? "error"           --> doFloatNoBorder
              , className =? "notification"    --> doFloatNoBorder
              , className =? "krunner"         --> doFloatNoBorder
              , className =? "Xfrun4"          --> doFloatNoBorder
              , className =? "Xfce4-notifyd"   --> doFloatNoBorder
              , title =?     "Screenshot"      --> doFloatNoBorder
              , className =? "plugin-browser"  --> doFloatNoBorder
              , className =? "Xfce-polkit"     --> doFloatNoBorder
              , className =? "Xfce-polkit"     --> doFloatNoBorder
              , title =?     "Confirmation"    --> doFloatNoBorder
              , className =? "Ibus-setup"      --> doFloatNoBorder

              , className =? "firefox"         --> doShift ( myWorkspaces !! 1 )
              , className =? "librewolf"       --> doShift ( myWorkspaces !! 1 )
              , className =? "VSCodium"        --> doShift ( myWorkspaces !! 2 )
              , className =? "Microsoft Teams - Preview" --> doShift ( myWorkspaces !! 4 )
              , className =? "Slack"           --> doShift  ( myWorkspaces !! 4 )

              , isFullscreen -->  doFullFloat
              ]
              where role = stringProperty "WM_WINDOW_ROLE"

            -- myKeys :: List
            myKeys =
              -- XMonad Essentials
              [ ("M-S-r", restart "xmonad" True)      -- Restart XMonad
              , ("M-q", kill1)                        -- Kill focused window
              , ("M-S-q", killAll)                    -- Kill all windows on WS
              , ("M-S-b", sendMessage ToggleStruts)   -- Toggle bar show/hide

              -- Switch to workspace
              , ("M-1", (windows $ W.greedyView $ myWorkspaces !! 0)) -- Switch to workspace 1
              , ("M-2", (windows $ W.greedyView $ myWorkspaces !! 1)) -- Switch to workspace 2
              , ("M-3", (windows $ W.greedyView $ myWorkspaces !! 2)) -- Switch to workspace 3
              , ("M-4", (windows $ W.greedyView $ myWorkspaces !! 3)) -- Switch to workspace 4
              , ("M-5", (windows $ W.greedyView $ myWorkspaces !! 4)) -- Switch to workspace 5
              , ("M-6", (windows $ W.greedyView $ myWorkspaces !! 5)) -- Switch to workspace 6
              , ("M-7", (windows $ W.greedyView $ myWorkspaces !! 6)) -- Switch to workspace 7
              , ("M-8", (windows $ W.greedyView $ myWorkspaces !! 7)) -- Switch to workspace 8
              , ("M-9", (windows $ W.greedyView $ myWorkspaces !! 8)) -- Switch to workspace 9

              -- Send window to workspace
              , ("M-S-1", (windows $ W.shift $ myWorkspaces !! 0)) -- Send to workspace 1
              , ("M-S-2", (windows $ W.shift $ myWorkspaces !! 1)) -- Send to workspace 2
              , ("M-S-3", (windows $ W.shift $ myWorkspaces !! 2)) -- Send to workspace 3
              , ("M-S-4", (windows $ W.shift $ myWorkspaces !! 3)) -- Send to workspace 4
              , ("M-S-5", (windows $ W.shift $ myWorkspaces !! 4)) -- Send to workspace 5
              , ("M-S-6", (windows $ W.shift $ myWorkspaces !! 5)) -- Send to workspace 6
              , ("M-S-7", (windows $ W.shift $ myWorkspaces !! 6)) -- Send to workspace 7
              , ("M-S-8", (windows $ W.shift $ myWorkspaces !! 7)) -- Send to workspace 8
              , ("M-S-9", (windows $ W.shift $ myWorkspaces !! 8)) -- Send to workspace 9

              -- Move window to WS and go there
              , ("M-S-<Page_Up>", shiftTo Next nonNSP >> moveTo Next nonNSP)    -- Move window to next WS
              , ("M-S-<Page_Down>", shiftTo Prev nonNSP >> moveTo Prev nonNSP)  -- Move window to prev WS

              -- Toggle between current WS and WS displayed previously
              , ("M-§", toggleWS)

              -- Window navigation
              , ("M-<Right>", windows W.focusDown)  -- Move focus to next window
              , ("M-<Left>", windows W.focusUp)     -- Move focus to prev window
              , ("M-S-<Right>", windows W.swapDown) -- Swap focused window with next window
              , ("M-S-<Left>", windows W.swapUp)    -- Swap focused window with prev window
              , ("M-m", windows W.focusMaster)      -- Move focus to master window
              , ("M-S-m", windows W.swapMaster)     -- Swap focused window with master window
              , ("M-<Backspace>", promote)          -- Move focused window to master
              , ("M-S-,", rotSlavesDown)            -- Rotate all windows except master
              , ("M-S-.", rotAllDown)               -- Rotate all windows current stack

              -- Programs and launcers
              , ("M-d", spawn "j4-dmenu-desktop")             -- App launcher
              , ("M-x", spawn "${dm-logout}/bin/dm-logout")   -- Logout Menu
              , ("M-l", spawn "xflock4")                      -- Lock Screen
              , ("M-p", spawn "${dm-vpn}/bin/dm-vpn")         -- VPN Menu
              , ("M-,", spawn "xfce4-settings-manager")       -- Settings
              , ("M-S-w", spawn "${dm-librewolf-profile}/bin/dm-librewolf-profile")   -- Librewolf profile menu
              , ("M-e", spawn "thunar")                       -- File browser
              , ("M-<Return>", spawn (myTerminal))            -- Terminal
              , ("M-w", spawn (myBrowser))                    -- Web browser
              , ("M-S-i", spawn "${toggle-kbd-variant}/bin/toggle-kbd-variant") -- Switch keyboard variant
              , ("M-v", spawn "${pkgs.pavucontrol}/bin/pavucontrol") -- Volume control

              -- Monitors"
              , ("M-.", nextScreen) -- Switch focus to next monitor

              -- Switch layouts
              , ("M-<Space>", sendMessage NextLayout)                               -- Switch to next layout
              , ("M-M1-<Space>", cycleThroughLayouts ["monocle", "tall"])           -- Switch between tall and monocle
              , ("M-f", sendMessage (MT.Toggle NBFULL) >> sendMessage ToggleStruts) -- Toggle noborders/full

              -- Window resizing
              , ("M-M1-h", sendMessage Shrink)        -- Shrink window
              , ("M-M1-l", sendMessage Expand)        -- Expand window
              , ("M-M1-j", sendMessage MirrorShrink)  -- Shrink window vertically
              , ("M-M1-k", sendMessage MirrorExpand)  -- Expand window vertically

              -- Increase/decrease windows in the master pane or the stack
              , ("M-S-<Up>", sendMessage (IncMasterN 1))      -- Increase clients in master pane
              , ("M-S-<Down>", sendMessage (IncMasterN (-1))) -- Decrease clients in master pane
              , ("M-+", increaseLimit)                        -- Increase max # of windows for layout
              , ("M--", decreaseLimit)                        -- Decrease max # of windows for layout

              -- Scratchpads
              -- Toggle show/hide these programs. They run on a hidden workspace.
              , ("M-s t", namedScratchpadAction myScratchPads "terminal")    -- Toggle scratchpad terminal
              , ("M-s c", namedScratchpadAction myScratchPads "calculator")] -- Toggle scratchpad calculator
              -- The following lines are needed for named scratchpads.
                where nonNSP          = WSIs (return (\ws -> W.tag ws /= "NSP"))
                      nonEmptyNonNSP  = WSIs (return (\ws -> isJust (W.stack ws) && W.tag ws /= "NSP"))

            myLogHook :: D.Client -> PP
            myLogHook dbus =
              def
                { ppOutput = dbusOutput dbus,
                  ppCurrent = wrap ("%{F" ++ base0BColor ++ "}%{o" ++ base0BColor ++ "}%{+o}") "%{-o}%{F-}",
                  ppVisible = wrap ("%{F" ++ base0BColor ++ "}") "%{F-}",
                  ppUrgent = wrap ("%{F" ++ base09Color ++ "}") "%{F-}",
                  ppHidden = wrap ("%{F" ++ base0CColor ++ "}") "%{F-}",
                  ppLayout = wrap ("%{F" ++ base0FColor ++ "}") "%{F-}",
                  ppHiddenNoWindows = wrap ("%{F" ++ base02Color ++ "}") "%{F-}",
                  ppTitle = const " ", -- shorten 55
                  ppWsSep = " ",
                  ppSep = "%{F#666666} |  %{F-}"
                }

            -- Emit a DBus signal on log updates
            dbusOutput :: D.Client -> String -> IO ()
            dbusOutput dbus str = do
                let signal = (D.signal objectPath interfaceName memberName) {
                        D.signalBody = [D.toVariant $ UTF8.decodeString str]
                    }
                D.emit dbus signal
              where
                objectPath = D.objectPath_ "/org/xmonad/Log"
                interfaceName = D.interfaceName_ "org.xmonad.Log"
                memberName = D.memberName_ "Update"

            -- Helpers
            setFullscreenSupported :: X ()
            setFullscreenSupported = addSupported ["_NET_WM_STATE", "_NET_WM_STATE_FULLSCREEN"]

            addSupported :: [String] -> X ()
            addSupported props = withDisplay $ \dpy -> do
                r <- asks theRoot
                a <- getAtom "_NET_SUPPORTED"
                newSupportedList <- mapM (fmap fromIntegral . getAtom) props
                io $ do
                  supportedList <- fmap (join . maybeToList) $ getWindowProperty32 dpy a r
                  changeProperty32 dpy r a aTOM propModeReplace (nub $ newSupportedList ++ supportedList)

            -- Makes setting the spacingRaw simpler to write. The spacingRaw module adds a configurable amount of space around windows.
            -- No borders are applied if fewer than two windows. So  window has no gaps.
            mySpacing :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
            mySpacing i = spacingRaw True (Border i i i i) True (Border i i i i) True

            doFloatNoBorder :: ManageHook
            doFloatNoBorder = doCenterFloat <+> hasBorder False
          '';
        };
      };
    };
  };
}

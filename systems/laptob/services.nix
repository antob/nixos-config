let enabled = { enable = true; };
in {
  services = {
    logind = {
      lidSwitch = "suspend-then-hibernate";
      lidSwitchExternalPower = "suspend";
    };

    avahi = {
      enable = true;
      nssmdns = true;
    };

    # Enable the OpenSSH daemon.
    openssh = enabled;

    # Enable CUPS to print documents.
    printing = enabled;

    gnome.gnome-keyring.enable = true;
    upower.enable = true;

    dbus = {
      enable = true;
      # packages = [ pkgs.gnome3.dconf ];
    };

    xserver = {
      # Enable the X11 windowing system.
      enable = true;

      # Configure keymap in X11
      layout = "se,se";
      xkbVariant = ",us";
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

      # Enable the XFCE Desktop Environment.
      displayManager.lightdm.enable = true;
      desktopManager.xfce = {
        enable = true;
        # noDesktop = true;
        # enableXfwm = false;
      };

      # windowManager = {
      #   xmonad = {
      #     enable = true;
      #     enableContribAndExtras = true;
      #     extraPackages = haskellPackages: [
      #       haskellPackages.xmonad-contrib
      #       haskellPackages.xmonad-extras
      #       haskellPackages.xmonad
      #     ];
      #   };
      # };

      # Enable automatic login for the user.
      displayManager.autoLogin.enable = true;
      displayManager.autoLogin.user = "tob";
      # displayManager.defaultSession = "xfce+xmonad";
    };
  };
}

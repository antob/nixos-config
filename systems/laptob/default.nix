# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, outputs, lib, config, pkgs, ... }:

let enabled = { enable = true; };
in {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example
    outputs.nixosModules.user
    outputs.nixosModules.hardware.networking
    outputs.nixosModules.hardware.fingerprint
    outputs.nixosModules.system.locale
    outputs.nixosModules.system.console

    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd
    inputs.impermanence.nixosModules.impermanence

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
  ];

  host = {
    name = "laptob";

    user = {
      name = "tob";
      fullName = "Tobias Lindholm";
      email = "tobias.lindholm@antob.se";
      initialPassword = "password";
      autoLogin = true;
    };

    hardware = {
      networking = enabled;
      fingerprint = enabled;
    };

    system = {
      locale = enabled;
      console = enabled;
    };
  };

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
    openssh.enable = true;

    # Enable CUPS to print documents.
    printing.enable = true;
  };

  # Necessary for user-specific impermanence
  programs.fuse.userAllowOther = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"

    ];
    files = [
      "/etc/machine-id"
      "/ssh/ssh_host_rsa_key"
      "/ssh/ssh_host_rsa_key.pub"
      "/ssh/ssh_host_ed25519_key"
      "/ssh/ssh_host_ed25519_key.pub"
    ];
  };

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Set your time zone.
  time.timeZone = "Europe/Stockholm";

  # List packages installed in system profile.
  environment.systemPackages = with pkgs;
    [
      #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      wget
    ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    # Bootloader.
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "max";
        configurationLimit = 5;
      };

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/efi";
      };
    };
  };

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.modifications
      outputs.overlays.additions

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default
    ];

    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}")
      config.nix.registry;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
    };
  };

  # services.xserver = {
  #   # Enable the X11 windowing system.
  #   enable = true;

  #   # Configure keymap in X11
  #   layout = "se";
  #   xkbVariant = "";

  #   # Enable the XFCE Desktop Environment.
  #   displayManager.lightdm.enable = true;
  #   desktopManager.xfce.enable = true;

  #   # Enable automatic login for the user.
  #   displayManager.autoLogin.enable = true;
  #   displayManager.autoLogin.user = "tob";
  # };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}

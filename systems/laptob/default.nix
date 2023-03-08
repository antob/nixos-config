{ inputs, outputs, lib, config, pkgs, ... }:

let enabled = { enable = true; };
in {
  imports = outputs.nixosModules.all ++ [
    inputs.impermanence.nixosModules.impermanence

    ./persist.nix
    ./services.nix
    ./programs.nix
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
      audio = enabled;
      fingerprint = enabled;
    };

    system = {
      locale = enabled;
      console = enabled;
    };
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs;
    [
      #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      wget
    ];

  # Set your time zone.
  time.timeZone = "Europe/Stockholm";

  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # systemd.services.upower.enable = true;

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

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}

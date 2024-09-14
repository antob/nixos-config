{ pkgs, lib, ... }:

with lib;
with lib.antob;
{
  # `install-iso` adds wireless support that
  # is incompatible with networkmanager.
  networking.wireless.enable = mkForce false;

  antob = {
    apps = {
      firefox = enabled;
      vscodium = enabled;
    };

    tools = {
      kitty = enabled;
      git = enabled;
      zsh = enabled;
      starship = enabled;
      eza = enabled;
    };

    cli-apps = {
      neovim = enabled;
      helix = enabled;
      tmux = enabled;
    };

    hardware = {
      bluetooth = enabled;
      yubikey = enabled;
      networking = enabled;
      audio = enabled;
    };

    desktop.gnome = enabled;

    services = {
      openssh = enabled;
      printing = enabled;
    };

    security.gpg = enabled;

    system = {
      fonts = enabled;
      locale = enabled;
      time = enabled;
      console = enabled;
    };

    virtualisation.docker.enable = false;
    virtualisation.podman.enable = false;
  };

  environment.systemPackages = with pkgs; [
    chromium
    gnome-calculator
  ];

  system.stateVersion = "22.11";
}

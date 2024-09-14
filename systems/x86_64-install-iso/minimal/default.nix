{ pkgs, lib, ... }:

with lib;
with lib.antob;
{
  # `install-iso` adds wireless support that
  # is incompatible with networkmanager.
  networking.wireless.enable = mkForce false;

  antob = {
    tools = {
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
      networking = enabled;
    };

    services = {
      openssh = enabled;
    };

    system = {
      fonts = enabled;
      locale = enabled;
      time = enabled;
      console = enabled;
    };

    virtualisation.docker.enable = false;
    virtualisation.podman.enable = false;
  };

  system.stateVersion = "22.11";
}

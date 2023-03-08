{ inputs, outputs, lib, config, pkgs, ... }:

let enabled = { enable = true; };

in {
  # You can import other home-manager modules here
  imports = outputs.homeManagerModules.all ++ [
    inputs.impermanence.nixosModules.home-manager.impermanence

    ./services.nix
    ./programs.nix
    ./persist.nix
    ./xfconf_dconf.nix
    ./gtk.nix
  ];

  host = {
    user = {
      name = "tob";
      fullName = "Tobias Lindholm";
      email = "tobias.lindholm@antob.se";
    };

    tools = {
      git = enabled;
      neovim = enabled;
      zsh = enabled;
      starship = enabled;
      exa = enabled;
      alacritty = enabled;
    };

    security.gpg = enabled;
  };

  xdg.enable = true;
  xsession.enable = true;

  home.packages = with pkgs; [
    firefox
    htop
    gopass
    bottom
    ripgrep
    fd
    gitui
    lazygit
    font-manager
    (nerdfonts.override { fonts = [ "Hack" ]; })
  ];

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  # home.stateVersion = config.system.stateVersion;
  home.stateVersion = "22.11";
}

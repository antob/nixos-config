{ inputs, outputs, lib, config, pkgs, ... }:

let enabled = { enable = true; };

in {
  # You can import other home-manager modules here
  imports = outputs.homeManagerModules.all
    ++ [ inputs.impermanence.nixosModules.home-manager.impermanence ];

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
    };
  };

  # home.file = mkAliasDefinitions options.host.home.file;
  xdg.enable = true;
  # xdg.configFile = mkAliasDefinitions options.host.home.configFile;

  # xsession.enable = true;

  home.persistence = {
    "/persist/home/tob" = {
      directories = [ "Projects" ".local/share/zsh" ".ssh" ];
      allowOther = true;
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # # Add stuff for your user as you see fit:
  # programs.neovim = {
  #   enable = true;
  #   vimAlias = true;
  # };

  home.packages = with pkgs; [ firefox htop ];

  # fontProfiles = {
  #   enable = true;
  #   monospace = {
  #     family = "FiraCode Nerd Font";
  #     package = pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; };
  #   };
  #   regular = {
  #     family = "Fira Sans";
  #     package = pkgs.fira;
  #   };
  # };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  # home.stateVersion = config.system.stateVersion;
  home.stateVersion = "22.11";
}

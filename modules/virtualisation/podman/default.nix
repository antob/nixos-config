{ options, config, lib, pkgs, ... }:

with lib;
let cfg = config.antob.virtualisation.podman;
in {
  options.antob.virtualisation.podman = with types; {
    enable = mkEnableOption "Whether or not to enable Podman.";
  };

  config = mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
    };

    antob = {
      home.extraOptions = {
        home.shellAliases = { "docker-compose" = "podman-compose"; };
      };

      persistence.directories = [ "/var/lib/containers" ];
      user.extraGroups = [ "podman" ];
      tools.zsh.extraOhMyZshPlugins = [ "docker-compose" ];
    };

    environment.systemPackages = with pkgs; [ podman-compose docker-compose ];
  };
}

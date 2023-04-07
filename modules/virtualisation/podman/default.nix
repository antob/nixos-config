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

    virtualisation.containers.storage.settings = {
      storage = {
        driver = "btrfs";
        graphroot = "/persist/var/lib/containers/storage";
        runroot = "/run/containers/storage";
        rootless_storage_path = "/persist/home/${config.antob.user.name}/.local/share/containers";
      };
    };

    antob = {
      home.extraOptions = {
        home.shellAliases = { "docker-compose" = "podman-compose"; };
      };

      persistence = {
        directories = [ "/var/lib/containers" "/run/containers" ];
        home.directories = [ ".local/share/containers" ];
      };

      user.extraGroups = [ "podman" ];
      tools.zsh.extraOhMyZshPlugins = [ "docker-compose" ];
    };

    environment.systemPackages = with pkgs; [ podman-compose docker-compose ];
  };
}

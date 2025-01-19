{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.virtualisation.docker;
in
{
  options.antob.virtualisation.docker = with types; {
    enable = mkEnableOption "Whether or not to enable docker.";
  };

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      storageDriver = "btrfs";
    };

    antob = {
      user.extraGroups = [ "docker" ];
      tools.zsh.extraOhMyZshPlugins = [ "docker-compose" ];
    };

    environment.systemPackages = with pkgs; [ docker-compose ];
  };
}

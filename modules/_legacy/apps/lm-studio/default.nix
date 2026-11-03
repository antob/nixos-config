{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.apps.lm-studio;
in
{
  options.antob.apps.lm-studio = with types; {
    enable = mkEnableOption "Enable LM Studio";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ lmstudio ];

    antob.home.extraOptions.home.file.".lmstudio-home-pointer".text =
      "/home/${config.antob.user.name}/.config/lmstudio";

    antob.persistence.home.directories = [
      ".config/LM Studio"
      ".config/lmstudio"
    ];
  };
}

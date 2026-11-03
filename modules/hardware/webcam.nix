{
  flake.modules.nixos.webcam =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    with lib;
    {
      config = {
        environment.systemPackages = with pkgs; [
          v4l-utils
          guvcview
        ];

        antob.persistence.home.directories = [
          ".config/guvcview2"
        ];
      };
    };

}

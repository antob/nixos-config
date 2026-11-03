{
  flake.modules.nixos.sqlit =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    {
      config = {
        environment.systemPackages = with pkgs; [
          sqlit-tui
        ];

        environment.variables = {
          SQLIT_CONFIG_DIR = "$HOME/.config/sqlit";
        };

        antob.persistence = {
          home.directories = [ ".config/sqlit" ];
        };
      };
    };

}

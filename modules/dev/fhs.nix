{
  flake.modules.nixos.fhs =
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
          (
            let
              base = pkgs.appimageTools.defaultFhsEnvArgs;
            in
            pkgs.buildFHSEnv (
              base
              // {
                name = "fhs";
                targetPkgs =
                  pkgs:
                  # pkgs.buildFHSUserEnv provides only a minimal FHS environment,
                  # lacking many basic packages needed by most software.
                  # Therefore, we need to add them manually.
                  #
                  # pkgs.appimageTools provides basic packages required by most software.
                  (base.targetPkgs pkgs)
                  ++ (with pkgs; [
                    pkg-config
                    ncurses
                    # Feel free to add more packages here if needed.
                  ]);
                profile = "export FHS=1";
                runScript = "bash";
                extraOutputsToInstall = [ "dev" ];
              }
            )
          )
        ];
      };
    };

}

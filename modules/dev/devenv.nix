{
  flake.modules.nixos.devenv =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    {
      config = {
        nix.settings = {
          keep-outputs = true;
          keep-derivations = true;
        };

        antob = {
          # home.extraOptions.programs.zsh.initContent = ''
          #   eval "$(${getExe pkgs.devenv} hook zsh)"
          # '';

          persistence.home.directories = [
            ".local/share/devenv"
          ];
        };

        environment.systemPackages = with pkgs; [
          cachix
          devenv
        ];
      };
    };

}

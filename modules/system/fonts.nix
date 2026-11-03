{ config, ... }:
let
  inherit (config.flake.lib) mkOpt;
  inherit (config.flake.modules) homeManager;
in
{
  flake.modules.nixos.fonts =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    with lib;
    {
      options.antob.fonts = with types; {
        fonts = mkOpt (listOf package) [ ] "Custom font packages to install.";
      };

      config = {
        home-manager.sharedModules = [ homeManager.fonts ];

        environment.variables = {
          # Enable icons in tooling since we have nerdfonts.
          LOG_ICONS = "true";
        };

        environment.systemPackages = with pkgs; [ font-manager ];

      };
    };

  flake.modules.homeManager.fonts =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    with lib;
    let
      cfg = osConfig.antob.fonts;
    in
    {
      fonts.fontconfig = {
        enable = true;
        defaultFonts = {
          emoji = [
            "Noto Color Emoji"
          ];
        };
      };
      home.packages =
        with pkgs;
        [
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          noto-fonts-color-emoji
          nerd-fonts.hack
          nerd-fonts.fira-code
          nerd-fonts.monaspace
          nerd-fonts.jetbrains-mono
          hack-font # Without nerd-fonts patch, for kitty
          roboto-mono
          monaspace
          jetbrains-mono
        ]
        ++ cfg.fonts;
    };

}

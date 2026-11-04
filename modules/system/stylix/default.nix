{ inputs, ... }:
{
  flake.modules.nixos.stylix =
    { lib, ... }:
    {
      imports = [ inputs.stylix.nixosModules.stylix ];

      # Source of truth for colours. Read them with `config.lib.stylix.colors`
      # (bare hex) or `.withHashtag`; HM halves use `osConfig.lib.stylix.colors`.
      stylix = {
        enable = true;
        # Targets are opted into by the aspect that configures the app.
        autoEnable = false;
        polarity = "dark";
        base16Scheme = lib.recursiveUpdate (import ./_files/tokyo-night-terminal-dark.nix) {
          # Upstream reuses base04 here, which makes default text too dim.
          palette.base05 = "#C0CAF5";
        };
      };
    };
}

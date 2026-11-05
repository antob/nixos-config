{
  flake.modules.nixos.chromium =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      c = config.lib.stylix.colors;
      rgb =
        n:
        map (ch: lib.toInt c."${n}-rgb-${ch}") [
          "r"
          "g"
          "b"
        ];

      # Unpacked theme extension, coloured like the Firefox Stylix target.
      theme = pkgs.writeTextDir "manifest.json" (
        builtins.toJSON {
          manifest_version = 3;
          name = "Stylix";
          version = "1.0";
          theme.colors = {
            frame = rgb "base00";
            frame_inactive = rgb "base00";
            frame_incognito = rgb "base00";
            frame_incognito_inactive = rgb "base00";
            background_tab = rgb "base00";
            background_tab_inactive = rgb "base00";
            background_tab_text = rgb "base04";
            toolbar = rgb "base01";
            tab_text = rgb "base05";
            toolbar_text = rgb "base05";
            toolbar_button_icon = rgb "base05";
            bookmark_text = rgb "base05";
            omnibox_background = rgb "base00";
            omnibox_text = rgb "base05";
            ntp_background = rgb "base00";
            ntp_text = rgb "base05";
            ntp_link = rgb "base0D";
          };
        }
      );
    in
    {
      environment.systemPackages = [
        (pkgs.ungoogled-chromium.override {
          commandLineArgs = "--load-extension=${theme}";
        })
      ];
    };
}

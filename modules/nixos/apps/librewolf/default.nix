{
  config,
  lib,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.apps.librewolf;
in
{
  options.antob.apps.librewolf = with types; {
    enable = mkEnableOption "Enable Librewolf";
  };

  config = mkIf cfg.enable {
    antob = {
      home.extraOptions.programs.librewolf = {
        enable = true;
        settings = {
          "privacy.clearOnShutdown.history" = false;
          "privacy.clearOnShutdown.downloads" = false;
          "browser.sessionstore.resume_from_crash" = true;
          "privacy.sanitize.sanitizeOnShutdown" = false;
          "webgl.disabled" = false;
          "media.ffmpeg.vaapi.enabled" = true;

          "general.smoothScroll.lines.durationMaxMS" = 125;
          "general.smoothScroll.lines.durationMinMS" = 125;
          "general.smoothScroll.mouseWheel.durationMaxMS" = 200;
          "general.smoothScroll.mouseWheel.durationMinMS" = 100;
          "general.smoothScroll.msdPhysics.enabled" = true;
          "general.smoothScroll.other.durationMaxMS" = 125;
          "general.smoothScroll.other.durationMinMS" = 125;
          "general.smoothScroll.pages.durationMaxMS" = 125;
          "general.smoothScroll.pages.durationMinMS" = 125;
          "layers.acceleration.force-enabled" = true;
          "mousewheel.min_line_scroll_amount" = 30;
          "mousewheel.system_scroll_override_on_root_content.enabled" = true;
          "mousewheel.system_scroll_override_on_root_content.horizontal.factor" = 175;
          "mousewheel.system_scroll_override_on_root_content.vertical.factor" = 175;
          "toolkit.scrollbox.horizontalScrollDistance" = 6;
          "toolkit.scrollbox.verticalScrollDistance" = 6;
        };
      };

      persistence.home.directories = [ ".librewolf" ];
    };
  };
}

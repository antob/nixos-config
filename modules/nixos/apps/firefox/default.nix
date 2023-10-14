{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.apps.firefox;
in {
  options.antob.apps.firefox = with types; {
    enable = mkEnableOption "Enable Firefox";
  };

  config = mkIf cfg.enable {
    antob = {
      home.extraOptions.programs.firefox = {
        enable = true;
        profiles.${config.antob.user.name} = {
          id = 0;
          name = config.antob.user.name;
          settings = {
            "browser.aboutwelcome.enabled" = false;
            "browser.meta_refresh_when_inactive.disabled" = true;
            "browser.startup.homepage" =
              "https://start.duckduckgo.com/?kak=-1&kal=-1&kao=-1&kaq=-1&kt=Hack+Nerd+Font&kae=d&ks=m&k7=2e3440&kj=3b4252&k9=eceff4&kaa=d8dee9&ku=1&k8=d8dee9&kx=81a1c1&k21=3b4252&k18=1&k5=2&kp=-2&k1=-1&kaj=u&kay=b&kk=-1&kax=-1&kap=-1&kau=-1";
            "browser.urlbar.suggest.quicksuggest.sponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.aboutConfig.showWarning" = false;
            "browser.ssb.enabled" = true;

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
            "mousewheel.system_scroll_override_on_root_content.horizontal.factor" =
              175;
            "mousewheel.system_scroll_override_on_root_content.vertical.factor" =
              175;
            "toolkit.scrollbox.horizontalScrollDistance" = 6;
            "toolkit.scrollbox.verticalScrollDistance" = 6;
          };
        };

      };

      persistence.home.directories = [ ".mozilla/firefox" ];
    };
  };
}

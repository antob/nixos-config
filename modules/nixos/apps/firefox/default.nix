{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.apps.firefox;

  # See https://restoreprivacy.com/firefox-privacy/
  commonSettings = {
    "browser.aboutwelcome.enabled" = false;
    "browser.meta_refresh_when_inactive.disabled" = true;
    "browser.urlbar.suggest.quicksuggest.sponsored" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
    "browser.aboutConfig.showWarning" = false;
    "browser.ssb.enabled" = true;
    "browser.startup.page" = 3;
    "browser.tabs.loadInBackground" = false;
    "browser.urlbar.tipShownCount.searchTip_onboard" = 4;
    "browser.newtabpage.activity-stream.feeds.topsites" = false;
    "browser.toolbars.bookmarks.visibility" = "never";
    "browser.urlbar.suggest.bookmark" = false;

    "datareporting.healthreport.uploadEnabled" = false;

    "network.http.referer.disallowCrossSiteRelaxingDefault.top_navigation" = true;
    "network.cookie.cookieBehavior" = 1;
    "network.cookie.lifetimePolicy" = 0;
    "network.dns.disablePrefetch" = true;
    "network.prefetch-next" = false;

    "privacy.annotate_channels.strict_list.enabled" = true;
    "privacy.fingerprintingProtection" = true;
    "privacy.partition.network_state.ocsp_cache" = true;
    "privacy.query_stripping.enabled" = true;
    "privacy.query_stripping.enabled.pbmode" = true;
    "privacy.trackingprotection.emailtracking.enabled" = true;
    "privacy.trackingprotection.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;
    "privacy.donottrackheader.enabled" = true;
    "privacy.globalprivacycontrol.enabled" = true;
    "privacy.resistFingerprinting" = false; # Disabled to make browser time correct
    "privacy.trackingprotection.fingerprinting.enabled" = true;
    "privacy.trackingprotection.cryptomining.enabled" = true;
    # "privacy.firstparty.isolate" = true;

    "geo.enabled" = false;
    # "webgl.disabled" = true;

    "app.shield.optoutstudies.enabled" = false;

    "signon.autofillForms" = false;
    "signon.firefoxRelay.feature" = "disabled";
    "signon.generation.enabled" = false;
    "signon.management.page.breach-alerts.enabled" = false;
    "signon.rememberSignons" = false;

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
    "mousewheel.with_control.action" = 1; # Scroll instead of zoom with ctrl+wheel
    "toolkit.scrollbox.horizontalScrollDistance" = 6;
    "toolkit.scrollbox.verticalScrollDistance" = 6;
    "toolkit.telemetry.enabled" = false;

    "media.ffmpeg.vaapi.enabled" = true;
    "media.navigator.enabled" = false;

    "dom.event.clipboardevents.enabled" = false;
  };

  commonExtensions = with pkgs.nur.repos.rycee.firefox-addons; [
    ublock-origin
    proton-pass
    duckduckgo-privacy-essentials
    multi-account-containers
    linkhints
  ];

in
{
  options.antob.apps.firefox = with types; {
    enable = mkEnableOption "Enable Firefox";
  };

  config = mkIf cfg.enable {
    antob = {
      home.extraOptions = {
        programs.firefox = {
          enable = true;
          profiles = {
            ${config.antob.user.name} = {
              id = 0;
              name = config.antob.user.name;
              search = {
                default = "DuckDuckGo";
                force = true;
              };
              settings = commonSettings;
              extensions.packages = commonExtensions;
            };

            "HL" = {
              id = 1;
              name = "HL";
              search = {
                default = "DuckDuckGo";
                force = true;
              };
              settings = commonSettings;
              extensions.packages = commonExtensions;
            };

            "OBIT" = {
              id = 2;
              name = "OBIT";
              search = {
                default = "DuckDuckGo";
                force = true;
              };
              settings = commonSettings;
              extensions.packages = commonExtensions;
            };
          };
        };

        xdg.mimeApps.defaultApplications = {
          "text/html" = [ "firefox.desktop" ];
          "text/xml" = [ "firefox.desktop" ];
          "x-scheme-handler/http" = [ "firefox.desktop" ];
          "x-scheme-handler/https" = [ "firefox.desktop" ];
        };
      };

      persistence.home.directories = [ ".mozilla/firefox" ];
    };
  };
}

{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.apps.firefox;

  betterfoxSettings = {
    enable = true;
    fastfox.enable = true;
    securefox = {
      enable = true;
      passwords.enable = true;
    };
    peskyfox.enable = true;
    smoothfox = {
      enable = true;
      smooth-scrolling.enable = true;
    };
  };

  # Betterfox overrides
  commonSettings = {
    ## FASTFOX
    "browser.sessionstore.restore_pinned_tabs_on_demand" = true;

    ## SECUREFOX
    "signon.rememberSignons" = false; # disable password manager
    "extensions.formautofill.addresses.enabled" = false; # disable address manager
    "extensions.formautofill.creditCards.enabled" = false; # disable credit card manager
    "browser.urlbar.suggest.recentsearches" = false; # unselect "Show recent searches" for clean UI
    "browser.urlbar.showSearchSuggestionsFirst" = false; # unselect "Show search suggestions ahead of browsing history in address bar results" for clean UI
    # "browser.urlbar.groupLabels.enabled" = false; # hide Firefox Suggest label in URL dropdown box
    "signon.management.page.breach-alerts.enabled" = false; # extra hardening
    "signon.autofillForms" = false; # unselect "Autofill logins and passwords" for clean UI
    "signon.generation.enabled" = false; # unselect "Suggest and generate strong passwords" for clean UI
    "signon.firefoxRelay.feature" = ""; # unselect suggestions from Firefox Relay for clean UI
    "browser.safebrowsing.downloads.enabled" = false; # deny SB to scan downloads to identify suspicious files; local checks only
    "browser.safebrowsing.downloads.remote.url" = ""; # enforce no remote checks for downloads by SB
    "browser.safebrowsing.downloads.remote.block_potentially_unwanted" = false; # clean up UI; not needed in user.js if remote downloads are disabled
    "browser.safebrowsing.downloads.remote.block_uncommon" = false; # clean up UI; not needed in user.js if remote downloads are disabled
    "browser.safebrowsing.allowOverride" = false; # do not allow user to override SB
    "browser.search.update" = false; # do not update opensearch engines
    "network.trr.confirmationNS" = "skip"; # skip TRR confirmation request
    "extensions.webextensions.restrictedDomains" = ""; # remove Mozilla domains so adblocker works on pages
    "identity.fxaccounts.enabled" = false; # disable Firefox Sync
    "browser.firefox-view.feature-tour" = "{\"screen\":\"\",\"complete\":true}"; # disable the Firefox View tour from popping up for new profiles
    "accessibility.force_disabled" = 1; # disable Accessibility features
    "security.cert_pinning.enforcement_level" = 2; # strict public key pinning
    "privacy.userContext.enabled" = true; # enable container tabs

    # make Strict ETP less aggressive
    "browser.contentblocking.features.strict" =
      "tp,tpPrivate,cookieBehavior5,cookieBehaviorPBM5,cm,fp,stp,emailTP,emailTPPrivate,-lvl2,rp,rpTop,ocsp,qps,qpsPBM,fpp,fppPrivate,3pcd,btp";

    ## PESKYFOX
    # "cookiebanners.service.mode" = 0; # disable for performance since I'm using Easylist Cookie
    # "cookiebanners.service.mode.privateBrowsing" = 0; # disable for performance since I'm using Easylist Cookie
    "devtools.accessibility.enabled" = false; # removes un-needed "Inspect Accessibility Properties" on right-click
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false; # Settings>Home>Firefox Home Content>Recent Activity>Shortcuts>Sponsored shortcuts
    "browser.newtabpage.activity-stream.showSponsored" = false; # Settings>Home>Firefox Home Content>Recent Activity>Recommended by Pocket>Sponsored Stories
    "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false; # Settings>Home>Firefox Home Content>Recent Activity>Bookmarks
    "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false; # Settings>Home>Firefox Home Content>Recent Activity>Most Recent Download
    "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false; # Settings>Home>Firefox Home Content>Recent Activity>Visited Pages
    "browser.newtabpage.activity-stream.section.highlights.includePocket" = false; # Settings>Home>Firefox Home Content>Recent Activity>Pages Saved to Pocket
    # "browser.download.useDownloadDir" = true; # use direct downloads
    # "browser.download.folderList" = 0; # 0=desktop, 1=downloads, 2=last used
    "browser.toolbars.bookmarks.visibility" = "never"; # always hide bookmark bar
    "browser.startup.homepage_override.mstone" = "ignore"; # What's New page after updates; master switch
    # "browser.urlbar.suggest.history" = false; # Browsing history; hide URL bar dropdown suggestions
    "browser.urlbar.suggest.bookmark" = false; # Bookmarks; hide URL bar dropdown suggestions
    # "browser.urlbar.suggest.openpage" = false; # Open tabs; hide URL bar dropdown suggestions
    "browser.urlbar.suggest.topsites" = false; # Shortcuts; disable dropdown suggestions with empty query
    "browser.urlbar.suggest.engines" = false; # Search engines; tab-to-search
    "browser.urlbar.quicksuggest.enabled" = false; # hide Firefox Suggest UI in the settings
    # "browser.urlbar.maxRichResults" = 1; # minimum suggestion needed for URL bar autofill
    # "browser.bookmarks.max_backups" = 0; # minimize disk use; manually back-up
    "view_source.wrap_long_lines" = true; # wrap source lines
    "devtools.debugger.ui.editor-wrapping" = true; # wrap lines in devtools
    "browser.zoom.full" = false; # text-only zoom, not all elements on page
    "pdfjs.sidebarViewOnLoad" = 2; # force showing of Table of Contents in sidebar for PDFs (if available)
    "layout.word_select.eat_space_to_next_word" = false; # do not select the space next to a word when selecting a word
    # "browser.tabs.loadInBackground" = false; # CTRL+SHIFT+CLICK for background tabs; Settings>General>Tabs>When you open a link, image or media in a new tab, switch to it immediately
    "browser.tabs.loadBookmarksInTabs" = true; # force bookmarks to open in a new tab, not the current tab
    "ui.key.menuAccessKey" = 0; # remove underlined characters from various settings
    "general.autoScroll" = false; # disable unintentional behavior for middle click
    "ui.SpellCheckerUnderlineStyle" = 1; # dots for spell check errors
    "media.videocontrols.picture-in-picture.display-text-tracks.size" = "small"; # PiP
    "media.videocontrols.picture-in-picture.urlbar-button.enabled" = false; # PiP in address bar
    "reader.parse-on-load.enabled" = false; # disable reader mode
    # "reader.color_scheme" = "auto"; # match system theme for when reader is enabled
    # "browser.urlbar.openintab" = true; # stay on current site and open new tab when typing in URL bar

    ## DELETE IF NOT LINUX LAPTOP
    "network.trr.mode" = 2; # enable TRR (with System fallback)
    "network.trr.max-fails" = 5; # lower max attempts to use DoH
    "geo.provider.use_geoclue" = false; # [LINUX]
    "pdfjs.defaultZoomValue" = "page-width"; # PDF zoom level

    "browser.startup.page" = 3; # Resume the previous browser session
    "network.http.referer.disallowCrossSiteRelaxingDefault.top_navigation" = true;
    "network.cookie.cookieBehavior" = 1; # Allow cookies from originating server only
    "privacy.donottrackheader.enabled" = true;
    "geo.enabled" = false; # Disable location-aware browsing
    "browser.contentblocking.report.lockwise.enabled" = false;
    "browser.meta_refresh_when_inactive.disabled" = true;
    "browser.urlbar.tipShownCount.searchTip_onboard" = 4;
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
    "layout.spellcheckDefault" = 0;
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
        imports = [
          inputs.betterfox.homeManagerModules.betterfox
        ];

        programs.firefox = {
          enable = true;
          betterfox.enable = true;
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
              betterfox = betterfoxSettings;
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
              betterfox = betterfoxSettings;
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
              betterfox = betterfoxSettings;
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

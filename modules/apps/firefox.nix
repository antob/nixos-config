{ inputs, config, ... }:
let
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.firefox =
    { config, lib, ... }:

    {
      config = {
        home-manager.sharedModules = [ homeManager.firefox ];

        antob = {

          persistence.home.directories = [ ".config/mozilla/firefox" ];
        };
      };
    };

  flake.modules.homeManager.firefox =
    {
      config,
      osConfig,
      lib,
      pkgs,
      ...
    }:
    with lib;
    let
      userHome = "/home/${osConfig.antob.user.name}";
      hexColors = osConfig.lib.stylix.colors.withHashtag;
      channel = base: ch: toInt osConfig.lib.stylix.colors."${base}-rgb-${ch}";
      mkColor = base: {
        r = channel base "r";
        g = channel base "g";
        b = channel base "b";
      };
      selection = mkColor "base03";
      # Firefox Color theme from the Stylix scheme.
      stylixTheme =
        let
          frame = mkColor "base00";
          panel = mkColor "base01";
          toolbar = mkColor "base02";
          highlight = mkColor "base02";
          text = mkColor "base05";
          accent = mkColor "base0C";
        in
        {
          title = "Stylix";
          images.additional_backgrounds = [ ];
          colors = {
            inherit frame toolbar;
            frame_inactive = frame;
            tab_background_text = text;
            tab_text = text;
            tab_selected = toolbar;
            tab_line = toolbar; # hides the selected-tab outline
            tab_loading = text;
            tab_background_separator = toolbar;
            toolbar_text = text;
            icons = text;
            icons_attention = text;
            bookmark_text = text;
            button_background_active = frame;
            toolbar_bottom_separator = frame;
            toolbar_vertical_separator = frame;
            toolbar_field = frame;
            toolbar_field_text = text;
            toolbar_field_focus = frame;
            toolbar_field_border = frame;
            toolbar_field_border_focus = accent;
            toolbar_field_separator = toolbar;
            toolbar_field_highlight = selection;
            toolbar_field_highlight_text = text;
            popup = panel;
            popup_text = text;
            popup_border = frame;
            popup_highlight = highlight;
            popup_highlight_text = text;
            sidebar = frame;
            sidebar_text = text;
            sidebar_border = toolbar;
            sidebar_highlight = selection;
            sidebar_highlight_text = text;
            ntp_background = frame;
            ntp_text = text;
          };
        };
      betterfoxSettings = {
        securefox = {
          enable = true;
          passwords.enable = true;
        };
        peskyfox.enable = true;
        smoothfox.smooth-scrolling.enable = true;
      };
      commonSettings = {
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
        "extensions.autoDisableScopes" = 0; # don't auto-disable add-ons installed by Home Manager
        # HM disables this when extensions.settings is used, which hides every add-on's saved data.
        # Firefox Color still imports its storage.js once, into its empty database.
        "extensions.webextensions.ExtensionStorageIDB.enabled" = true;
        # Lets Firefox Color re-import storage.js after resetFirefoxColor empties its database.
        "extensions.webextensions.ExtensionStorageIDB.migrated.FirefoxColor@mozilla.com" = false;
        "browser.uidensity" = 2; # touch density: taller tabs and toolbar

        # System colours used where the Firefox Color theme doesn't reach (sidebar, dialogs, pages).
        "ui.accentcolor" = hexColors.base0C;
        "ui.accentcolortext" = hexColors.base00;
        "ui.highlight" = hexColors.base03;
        "ui.highlighttext" = hexColors.base05;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true; # load userChrome.css
        "browser.formfill.enable" = lib.mkForce true; # remember form field entries

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
        "browser.tabs.loadInBackground" = false; # CTRL+SHIFT+CLICK for background tabs; Settings>General>Tabs>When you open a link, image or media in a new tab, switch to it immediately
        "browser.tabs.loadBookmarksInTabs" = true; # force bookmarks to open in a new tab, not the current tab
        "browser.tabs.insertAfterCurrent" = false; # if true, open new tab next to current tab, not at the end
        "browser.ctrlTab.sortByRecentlyUsed" = true; # CTRL+TAB to switch tabs in order of use
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
        "pdfjs.defaultZoomValue" = "page-actual"; # PDF zoom level

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
        "apz.gtk.pangesture.page_delta_mode_multiplier" = 0.1; # Make touchpad scrolling less sensitive
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
        "layout.spellcheckDefault" = 0;
      };
      # Firefox hard-codes a yellow dotted outline on the focused row of tree lists (sidebar, Library).
      userChrome = ''
        treechildren::-moz-tree-row(current, focus) {
          outline: 1px solid ${hexColors.base0C} !important;
          outline-offset: -1px !important;
        }
      '';
      commonExtensions = {
        packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          duckduckgo-privacy-essentials
          multi-account-containers
          linkhints
          bitwarden
          firefox-color
        ];
        settings."FirefoxColor@mozilla.com" = {
          force = true;
          settings = {
            firstRunDone = true;
            theme = stylixTheme;
          };
        };
      };
    in
    {
      imports = [
        inputs.betterfox.homeModules.betterfox
      ];

      # Firefox Color imports storage.js only into an empty database, so clear it when the theme
      # changes. Skips profiles in use; they are retried on the next activation (switch or boot).
      home.activation.resetFirefoxColor = hm.dag.entryAfter [ "linkGeneration" ] ''
        themeHash=${builtins.hashString "sha256" (builtins.toJSON stylixTheme)}
        for profile in ${
          concatMapStringsSep " " (p: escapeShellArg p.path) (attrValues config.programs.firefox.profiles)
        }; do
          dir=${escapeShellArg config.programs.firefox.configPath}/$profile
          stamp=$dir/.firefox-color-theme
          [[ -f $dir/prefs.js ]] || continue
          [[ -f $stamp && $(<"$stamp") == "$themeHash" ]] && continue

          if [[ -L $dir/lock ]]; then
            pid=$(readlink "$dir/lock"); pid=''${pid##*+}
            if [[ $(cat /proc/"$pid"/comm 2>/dev/null) == *firefox* ]]; then
              warnEcho "Firefox is running with profile $profile; Firefox Color theme not reset."
              continue
            fi
          fi

          uuid=$(grep -oP 'FirefoxColor@mozilla\.com\\":\\"\K[0-9a-f-]+' "$dir/prefs.js" || true)
          if [[ -n $uuid ]]; then
            run rm -rf -- "$dir/storage/default/moz-extension+++$uuid^userContextId=4294967295"
          fi
          run tee "$stamp" <<<"$themeHash" >/dev/null
        done
      '';

      # Only Stylix's reader-mode colours; the browser chrome uses stylixTheme.
      stylix.targets.firefox = {
        enable = true;
        fonts.enable = false;
        profileNames = [
          osConfig.antob.user.name
          "HL"
          "OBIT"
          "Puzzel"
        ];
      };

      programs.firefox = {
        enable = true;
        configPath = "${userHome}/.config/mozilla/firefox";
        profiles = {
          ${osConfig.antob.user.name} = {
            id = 0;
            inherit (osConfig.antob.user) name;
            search = {
              default = "ddg";
              privateDefault = "ddg";
              force = true;
            };
            settings = commonSettings;
            extensions = commonExtensions;
            inherit userChrome;
          };

          "HL" = {
            id = 1;
            name = "HL";
            search = {
              default = "ddg";
              privateDefault = "ddg";
              force = true;
            };
            settings = commonSettings;
            extensions = commonExtensions;
            inherit userChrome;
          };

          "OBIT" = {
            id = 2;
            name = "OBIT";
            search = {
              default = "ddg";
              privateDefault = "ddg";
              force = true;
            };
            settings = commonSettings;
            extensions = commonExtensions;
            inherit userChrome;
          };

          "Puzzel" = {
            id = 3;
            name = "Puzzel";
            search = {
              default = "ddg";
              privateDefault = "ddg";
              force = true;
            };
            settings = commonSettings;
            extensions = commonExtensions;
            inherit userChrome;
          };
        };

        betterfox = {
          enable = true;
          profiles = {
            ${osConfig.antob.user.name} = {
              settings = betterfoxSettings;
            };

            "HL" = {
              settings = betterfoxSettings;
            };

            "OBIT" = {
              settings = betterfoxSettings;
            };

            "Puzzel" = {
              settings = betterfoxSettings;
            };
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

}

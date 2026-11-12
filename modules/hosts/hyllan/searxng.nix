{
  flake.modules.nixos.hyllan =
    { config, ... }:

    let
      subdomain = "search";
      port = 8890;
      inherit (config.sops) secrets;
    in
    {
      services = {
        searx = {
          enable = true;
          # Must define SEARXNG_SECRET
          environmentFile = secrets.searxng_env.path;
          settings = {
            use_default_settings.engines.keep_only = [
              # general web
              "duckduckgo"
              "brave"
              "bing"
              "wikipedia"
              "wikidata"
              # news
              "duckduckgo news"
              "bing news"
              # it: docs, Q&A, code
              "nixos wiki"
              "mdn"
              "stackoverflow"
              "hackernews"
              "github"
              # packages (pypi.org search sits behind a bot challenge)
              "npm"
              "rubygems"
              "crates.io"
              "docker hub"
            ];

            server = {
              bind_address = "127.0.0.1";
              inherit port;
              base_url = "https://${subdomain}.antob.net/";
              secret_key = "$SEARXNG_SECRET";
              # Caddy already restricts access to LAN/WireGuard
              limiter = false;
              public_instance = false;
              image_proxy = false;
            };

            search = {
              formats = [
                "html"
                "json"
              ];
              # Single residential IP: back off one day instead of 15
              suspended_times = {
                cf_SearxEngineCaptcha = 86400;
              };
            };

            # Entries merge into the upstream engine of the same name
            engines =
              map
                (name: {
                  inherit name;
                  disabled = false;
                })
                [
                  "bing"
                  "nixos wiki"
                  "hackernews"
                ]
              # Keep package lookups out of `it`, they match any query
              ++
                map
                  (name: {
                    inherit name;
                    disabled = false;
                    categories = [ "packages" ];
                  })
                  [
                    "npm"
                    "crates.io"
                    "docker hub"
                  ]
              ++ [
                # Returns a full page for any query; rank it below the Q&A and wiki engines
                {
                  name = "mdn";
                  weight = 0.5;
                }
                # Upstream scraper no longer matches rubygems.org; use the official API
                {
                  name = "rubygems";
                  engine = "json_engine";
                  disabled = false;
                  categories = [ "packages" ];
                  search_url = "https://rubygems.org/api/v1/search.json?query={query}&page={pageno}";
                  url_query = "project_uri";
                  title_query = "name";
                  content_query = "info";
                }
              ];
          };
        };

        caddy.antobProxies."${subdomain}" = {
          hostName = "127.0.0.1";
          inherit port;
        };
      };

      # Fetches ClearURLs rules at startup, which fails before DNS is up
      systemd.services.searx = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
      };

      sops.secrets.searxng_env = { };
    };
}

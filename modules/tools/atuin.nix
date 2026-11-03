{ config, ... }:
let
  inherit (config.flake.lib) mkOpt mkBoolOpt;
  inherit (config.flake.modules) homeManager;
in
{
  flake.modules.nixos.atuin =
    {
      config,
      lib,
      ...
    }:

    with lib;
    {
      options.antob.atuin = with types; {
        autoSync = mkBoolOpt true "Whether or not to automatically sync atuin history. (default: true)";
        filterMode = mkOpt str "global" "The filter mode to use for atuin. (default: global)";
      };

      config = {
        home-manager.sharedModules = [ homeManager.atuin ];

        antob.persistence.safe.home.directories = [
          ".local/share/atuin"
        ];
      };
    };

  flake.modules.homeManager.atuin =
    { osConfig, lib, ... }:
    with lib;
    let
      cfg = osConfig.antob.atuin;
    in
    {
      programs.atuin = {
        enable = true;
        enableZshIntegration = true;
        flags = [ "--disable-up-arrow" ];
        daemon.enable = true;
        settings = {
          auto_sync = cfg.autoSync;
          sync_frequency = "5m";
          sync_address = "https://atuin.antob.net";
          update_check = false;
          search_mode = "daemon-fuzzy";
          filter_mode = cfg.filterMode;
          filter_mode_shell_up_key_binding = "host";
          show_tabs = false;
          prefers_reduced_motion = true;
          enter_accept = false;
        };
      };
    };

}

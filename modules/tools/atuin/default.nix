{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.tools.atuin;
in
{
  options.antob.tools.atuin = with types; {
    enable = mkEnableOption "Whether or not to enable atuin.";
    autoSync = mkBoolOpt true "Whether or not to automatically sync atuin history. (default: true)";
    filterMode = mkOpt str "global" "The filter mode to use for atuin. (default: global)";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions.programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      flags = [ "--disable-up-arrow" ];
      daemon.enable = true;
      settings = {
        auto_sync = cfg.autoSync;
        sync_frequency = "5m";
        sync_address = "https://atuin.antob.net";
        update_check = false;
        search_mode = "skim";
        filter_mode = cfg.filterMode;
        filter_mode_shell_up_key_binding = "host";
        show_tabs = false;
        prefers_reduced_motion = true;
        enter_accept = false;
      };
    };

    antob.persistence.home.directories = [
      ".config/atuin"
      ".local/share/atuin"
    ];
  };
}

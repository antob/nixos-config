# NOTE: Download selected model using: `voxtype setup model`
{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.cli-apps.voxtype;
in
{
  options.antob.cli-apps.voxtype = with types; {
    enable = mkEnableOption "Whether or not to enable voxtype.";
    modelName = mkOpt str "large-v3-turbo" "Name of the model to use for transcription.";
  };

  config = mkIf cfg.enable {
    antob = {
      home.extraOptions.xdg.configFile."voxtype/config.toml".text = # toml
        ''
          engine = "whisper"
          state_file = "auto"

          [audio]
          device = "default"
          max_duration_secs = 60
          sample_rate = 16000

          [audio.feedback]
          enabled = true
          theme = "default"
          volume = 0.1

          [hotkey]
          enabled = true
          key = "SCROLLLOCK"
          modifiers = []

          [meeting]
          enabled = true

          [output]
          fallback_to_clipboard = true
          mode = "type"
          pre_type_delay_ms = 0
          type_delay_ms = 0

          [output.notification]
          on_recording_start = false
          on_recording_stop = false
          on_transcription = false

          [status]
          icon_theme = "emoji"

          [whisper]
          language = "auto"
          model = "${cfg.modelName}"
          on_demand_loading = false
          translate = false
        '';

      persistence.home.directories = [
        ".local/share/voxtype"
      ];

      user.extraGroups = [ "input" ];
    };
  };
}

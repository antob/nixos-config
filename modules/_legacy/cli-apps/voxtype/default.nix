# NOTE: Download selected model using: `voxtype setup model`
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.cli-apps.voxtype;
in
{
  options.antob.cli-apps.voxtype = with types; {
    enable = mkEnableOption "Whether or not to enable voxtype.";
    package = mkOpt package pkgs.voxtype "The VoxType package to use.";
    modelName = mkOpt str "large-v3-turbo" "Name of the model to use for transcription.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cfg.package
    ];

    antob = {
      home.extraOptions = {
        xdg.configFile."voxtype/config.toml".text = # toml
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

        systemd.user.services.voxtype = {
          Unit = {
            Description = "VoxType push-to-talk voice-to-text daemon";
            Documentation = "https://voxtype.io";
            PartOf = [ "graphical-session.target" ];
            After = [
              "graphical-session.target"
              "pipewire.service"
              "pipewire-pulse.service"
            ];
          };

          Service = {
            Type = "simple";
            ExecStart = "${cfg.package}/bin/voxtype daemon";
            Restart = "on-failure";
            RestartSec = 5;
          };

          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
        };
      };

      persistence.home.directories = [
        ".local/share/voxtype"
      ];

      user.extraGroups = [ "input" ];
    };
  };
}

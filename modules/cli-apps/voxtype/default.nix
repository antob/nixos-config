# NOTE: Download selected model using: `voxtype setup model`
{
  config,
  lib,
  pkgs,
  inputs,
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
    antob.home.extraOptions = {
      imports = [ inputs.voxtype.homeManagerModules.default ];

      programs.voxtype = {
        enable = true;
        package = inputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system}.vulkan;
        service.enable = true;
        settings = {
          hotkey = {
            enabled = true;
            key = "SCROLLLOCK";
          };
          whisper = {
            model = cfg.modelName;
            language = "auto";
            translate = false;
          };
          audio.feedback = {
            enabled = true;
            theme = "default";
            volume = 0.1;
          };
          output.notification = {
            on_recording_start = false;
            on_recording_stop = false;
            on_transcription = false;
          };
          meeting.enabled = true;
        };
      };
    };

    antob.persistence.home.directories = [
      ".config/voxtype"
      ".local/share/voxtype"
    ];

    antob.user.extraGroups = [ "input" ];
  };
}

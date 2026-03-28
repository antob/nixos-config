{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.cli-apps.pi-coding-agent;
in
{
  options.antob.cli-apps.pi-coding-agent = with types; {
    enable = mkEnableOption "Whether or not to enable pi-coding-agent.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # pi-coding-agent
      python3
    ];

    environment.variables = {
      PI_CODING_AGENT_DIR = "$HOME/.config/pi";
      PATH = "$HOME/.config/pi/node_modules/.bin";
    };

    antob.persistence = {
      home.directories = [ ".config/pi" ];
    };

    antob.cli-apps.agent-browser.enable = true;
  };
}

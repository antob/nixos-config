{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.cli-apps.pi-coding-agent;
  userHome = "/home/${config.antob.user.name}";
in
{
  options.antob.cli-apps.pi-coding-agent = with types; {
    enable = mkEnableOption "Whether or not to enable pi-coding-agent.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # pi-coding-agent
      nodejs
      bun
      python3
      libsixel
    ];

    environment.variables = {
      # PI_CODING_AGENT_DIR = "$HOME/.config/pi";
      PATH = "${userHome}/.cache/.bun/bin";
    };

    antob.persistence = {
      home.directories = [
        ".pi"
        ".cache/bun"
        ".cache/.bun"
      ];
    };

    antob.cli-apps.agent-browser.enable = true;
  };
}

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.antob.cli-apps.pi-coding-agent;
  userHome = "/home/${config.antob.user.name}";
  entryAfter = inputs.home-manager.lib.hm.dag.entryAfter;
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

    antob.home.extraOptions = {
      home.activation.piAgentLink = entryAfter [ "writeBoundary" ] ''
        ln -sfn ${userHome}/Projects/pi-agent-config ${userHome}/.pi/agent
      '';
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

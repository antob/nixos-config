{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.cli-apps.agent-browser;
  userHome = "/home/${config.antob.user.name}";
  dataHome = "${userHome}/.local/share";
in
{
  options.antob.cli-apps.agent-browser = with types; {
    enable = mkEnableOption "Whether or not to enable agent-browser.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      agent-browser
    ];

    environment.variables = {
      AGENT_BROWSER_CONFIG = "$HOME/.config/agent-browser/config.json";
    };

    # PUPPETEER_EXECUTABLE_PATH=$(which chromium) bunx extract-stealth-evasions

    antob.home.extraOptions.home.file.".config/agent-browser/config.json".text = ''
      {
        "profile": "${dataHome}/agent-browser/profile",
        "executablePath": "${pkgs.ungoogled-chromium}/bin/chromium",
        "args": "--disable-blink-features=AutomationControlled",
        "extension": ["${./extensions/stealth}"]
      }
    '';
  };
}

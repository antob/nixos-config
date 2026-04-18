{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.antob.cli-apps.opencode;
  ocPkgs = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system};
  userHome = "/home/${config.antob.user.name}";
  configDir = "${userHome}/Projects/opencode-config";
  entryAfter = inputs.home-manager.lib.hm.dag.entryAfter;
in
{
  options.antob.cli-apps.opencode = with types; {
    enable = mkEnableOption "Whether or not to enable opencode.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      ocPkgs.opencode
    ];

    environment.shellAliases = {
      oc = "opencode";
    };

    antob.home.extraOptions = {
      home.activation.openCodeLink = entryAfter [ "writeBoundary" ] ''
        ln -sfn ${configDir} ${userHome}/.config/opencode
      '';
    };

    antob.persistence = {
      home.directories = [
        # ".config/opencode"
        ".local/share/opencode"
        ".local/state/opencode"
        ".cache/opencode"
      ];
    };
  };
}

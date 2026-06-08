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
  system = pkgs.stdenv.hostPlatform.system;
  llm-pkgs = inputs.llm-agents.packages.${system};
  jailed-lib = inputs.jailed-agents.lib.${system};
  jail = jailed-lib.internals.jail;
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
      uv
      libsixel
      rtk
      llm-pkgs.workmux
      (jailed-lib.makeJailedPi {
        name = "jpi";
        extraPkgs = with pkgs; [
          nodejs
          python3
          rtk
        ];
        extraReadwriteDirs = [ "~/.local/share/rtk" ];
        extraReadonlyDirs = [ "/nix/store" ];
        env = {
          RTK_TELEMETRY_DISABLED = 1;
        };
        baseJailOptions = with jail.combinators; [
          network
          time-zone
          no-new-session
          (fwd-env "PATH")
        ];
      })
    ];

    environment.shellAliases = {
      wt = "workmux";
    };

    environment.variables = {
      PATH = "${userHome}/.cache/.bun/bin:${userHome}/.local/bin";
      RTK_TELEMETRY_DISABLED = 1;
    };

    antob.home.extraOptions = {
      xdg.configFile."workmux/config.yaml".text = /* yaml */ ''
        nerdfont: true
        worktree_dir: ./.worktrees
      '';

      home.activation.piAgentLink = entryAfter [ "writeBoundary" ] ''
        ln -sfn ${userHome}/.pi/agent/skills ${userHome}/.agents/skills
      '';
    };

    antob.persistence = {
      home.directories = [
        ".pi"
        ".agents"
        ".cache/bun"
        ".cache/.bun"
        ".local/share/rtk"
        ".local/state/workmux"
        ".cache/workmux"
      ];
    };
  };
}

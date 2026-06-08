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

  pushState =
    key: toPush: state:
    state // { ${key} = state.${key} ++ [ toPush ]; };

  jail = inputs.jail-nix.lib.extend {
    inherit pkgs;
    basePermissions =
      combinators: with combinators; [
        (unsafe-add-raw-args "--proc /proc")
        (unsafe-add-raw-args "--dev /dev")
        (unsafe-add-raw-args "--tmpfs /tmp")
        (unsafe-add-raw-args "--tmpfs ~")
        (ro-bind "${pkgs.bash}/bin/sh" "/bin/sh")
        (add-path "/bin")
        (ro-bind "/usr/bin/env" "/usr/bin/env")
        (ro-bind "/etc/zoneinfo" "/etc/zoneinfo")
        (pushState "additionalRuntimeClosures" pkgs.bash)
        (add-pkg-deps [ pkgs.coreutils ])
        (readonly "/nix/store")
        fake-passwd
      ];
  };

  jailed-pi = jail "jpi" llm-pkgs.pi (
    with jail.combinators;
    [
      network
      time-zone
      no-new-session
      mount-cwd
      (fwd-env "PATH")
      (readwrite (noescape "~/.pi"))
      (readwrite (noescape "~/.local/share/rtk"))
      (add-pkg-deps (
        with pkgs;
        [
          bashInteractive
          curl
          wget
          jq
          git
          which
          ripgrep
          gnugrep
          gawkInteractive
          ps
          findutils
          gzip
          unzip
          gnutar
          diffutils
          gnused
          nodejs
          # python3
          rtk
        ]
      ))
    ]
  );
in
{
  options.antob.cli-apps.pi-coding-agent = with types; {
    enable = mkEnableOption "Whether or not to enable pi-coding-agent.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      llm-pkgs.pi
      jailed-pi
      nodejs
      bun
      python3
      uv
      rtk
      llm-pkgs.workmux
    ];

    environment.shellAliases = {
      wt = "workmux";
    };

    environment.variables = {
      # PATH = "${userHome}/.cache/.bun/bin:${userHome}/.local/bin";
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

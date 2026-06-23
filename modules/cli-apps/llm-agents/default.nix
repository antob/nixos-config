{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.antob.cli-apps.llm-agents;
  userHome = "/home/${config.antob.user.name}";
  entryAfter = inputs.home-manager.lib.hm.dag.entryAfter;
  system = pkgs.stdenv.hostPlatform.system;
  llm-pkgs = inputs.llm-agents.packages.${system};
  jail = inputs.jail-nix.lib.extend {
    inherit pkgs;
    additionalCombinators = import ./combinators.nix { inherit lib; };
  };

  commonJailOptions = with jail.combinators; [
    network
    time-zone
    no-new-session
    mount-cwd
    mount-git-root
    notifications
    wayland
    (fwd-env "PATH")
    (readonly "/nix/store")
    (readonly "/usr/bin/env")
    (readonly "/etc/zoneinfo")
    (try-fwd-env "LD_LIBRARY_PATH")
    (set-env "COLORTERM" "truecolor")

    (readwrite (noescape "~/.local/share/rtk"))

    # Ruby/Rails
    (try-fwd-env "BUNDLE_PATH")
    (try-fwd-env "GEM_HOME")
    (try-fwd-env "GEM_PATH")
    (try-fwd-env "RUBYLIB")
    (readonly-paths-from-var "BUNDLE_PATH" " ")
    (readonly-paths-from-var "GEM_HOME" " ")
    (readonly-paths-from-var "GEM_PATH" ":")

    # Python
    (try-fwd-env "PYTHONPATH")
    (readonly-paths-from-var "VIRTUAL_ENV" " ")

    # Node.js
    (try-readonly-path-from-git-root "node_modules")
  ];

  commonPkgs = with pkgs; [
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
    libnotify
    wl-clipboard
    gzip
    unzip
    gnutar
    diffutils
    gnused
    nodejs
    rtk
  ];

  claude-code-pkg =
    let
      raw = llm-pkgs.claude-code;
    in
    pkgs.writeShellScriptBin "claude" ''
      exec ${raw}/bin/claude --dangerously-skip-permissions "$@"
    '';

  # --- The Sandboxes ---
  makeJailedPi =
    {
      extraPkgs ? [ ],
    }:
    jail "jpi" llm-pkgs.pi (
      with jail.combinators;
      (
        commonJailOptions
        ++ [
          (readwrite (noescape "~/.pi"))

          (add-pkg-deps commonPkgs)
          (add-pkg-deps extraPkgs)
        ]
      )
    );

  makeJailedClaude =
    {
      extraPkgs ? [ ],
    }:
    jail "jclaude" claude-code-pkg (
      with jail.combinators;
      (
        commonJailOptions
        ++ [
          (readwrite (noescape "~/.config/claude"))
          (try-fwd-env "CLAUDE_CONFIG_DIR")

          (add-pkg-deps commonPkgs)
          (add-pkg-deps extraPkgs)
        ]
      )
    );
in
{
  options.antob.cli-apps.llm-agents = with types; {
    enable = mkEnableOption "Whether or not to enable LLM agents.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      llm-pkgs.pi
      (makeJailedPi { })
      llm-pkgs.claude-code
      (makeJailedClaude { })
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
      RTK_TELEMETRY_DISABLED = 1;
      CLAUDE_CONFIG_DIR = "${userHome}/.config/claude";
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
        ".local/share/rtk"
        ".local/state/workmux"
        ".cache/workmux"
        ".config/claude"
      ];
    };
  };
}

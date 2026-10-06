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
  inherit (pkgs.stdenv.hostPlatform) system;
  inherit (config.antob.user) group;
  user = config.antob.user.name;
  userHome = "/home/${user}";
  piPackage = inputs.pi-coding-agent.packages.${system}.pi;
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
    (readwrite (noescape "~/.cache/codebase-memory-mcp"))

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
    bun
    python3
    uv
    codebase-memory-mcp
  ];

  pi-pkg = pkgs.writeShellScriptBin "pi" ''
    exec ${piPackage}/bin/pi --approve --bash-guard-disabled "$@"
  '';

  # --- The Sandboxes ---
  makeJailedPi =
    {
      extraPkgs ? [ ],
    }:
    jail "jpi" pi-pkg (
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

  claude-code-pkg =
    let
      raw = llm-pkgs.claude-code;
    in
    pkgs.writeShellScriptBin "claude" ''
      exec ${raw}/bin/claude --dangerously-skip-permissions "$@"
    '';

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
    environment = {
      systemPackages = [
        piPackage
        (makeJailedPi { })
        llm-pkgs.claude-code
        (makeJailedClaude { })
        llm-pkgs.workmux
      ]
      ++ commonPkgs;

      shellAliases = {
        wm = "workmux";
      };

      variables = {
        RTK_TELEMETRY_DISABLED = 1;
        CLAUDE_CONFIG_DIR = "${userHome}/.config/claude";
      };
    };

    antob = {
      home.extraOptions = {
        xdg.configFile."workmux/config.yaml".text = /* yaml */ ''
          nerdfont: true
          agent: "pi"
          auto_name:
            command: "pi -p"
            model: "openrouter/openai/gpt-4o-mini"
          panes:
           - focus: true
           - focus: false
             split: horizontal
          files:
            copy:
              - .envrc
              - .env
            symlink:
              - node_modules
              - .devenv
              - .venv
          post_create:
            - direnv allow
            - direnv exec . true
          auto_update_check: false
        '';
      };

      cli-apps = {
        herdr = enabled;
        worktrunk = enabled;
      };

      persistence.home.directories = [
        ".pi"
        ".local/share/rtk"
        ".local/state/workmux"
        ".cache/workmux"
        ".config/claude"
      ];
    };

    fileSystems."${userHome}/.pi/agent" = {
      device = "${userHome}/Projects/pi-agent-config";
      options = [ "bind" ];
      fsType = "none";
    };

    systemd.tmpfiles.rules = [
      "d ${userHome}/.pi 0755 ${user} ${group} -"
    ];
  };
}

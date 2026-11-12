{ inputs, config, ... }:
let
  inherit (config.aspects) homeManager nixos;
in
{
  flake.modules.nixos.llm-agents =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (config.antob.user) group;
      user = config.antob.user.name;
      userHome = "/home/${user}";
      piPackage = pkgs.symlinkJoin {
        name = "pi";
        paths = [ inputs.pi-coding-agent.packages.${system}.pi ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/pi \
            --set PI_SKIP_VERSION_CHECK 1 \
            --set GIT_CONFIG_COUNT 2 \
            --set GIT_CONFIG_KEY_0 gpg.format \
            --set GIT_CONFIG_VALUE_0 ssh \
            --set GIT_CONFIG_KEY_1 user.signingkey \
            --set GIT_CONFIG_VALUE_1 ${config.sops.secrets.agent_signing_key.path}
        '';
      };
      llm-pkgs = inputs.llm-agents.packages.${system};
      jail = inputs.jail-nix.lib.extend {
        inherit pkgs;
        additionalCombinators = import ./_files/combinators.nix { inherit lib; };
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
        exec ${piPackage}/bin/pi --approve "$@"
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
              (readonly config.sops.secrets.agent_signing_key.path)

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
              (readonly config.sops.secrets.agent_signing_key.path)
              (try-fwd-env "CLAUDE_CONFIG_DIR")
              (try-fwd-env "CLAUDE_CODE_TMUX_TRUECOLOR")
              (try-fwd-env "CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY")

              (add-pkg-deps commonPkgs)
              (add-pkg-deps extraPkgs)
            ]
          )
        );
    in
    {
      imports = with nixos; [
        herdr
        worktrunk
      ];

      config = {
        home-manager.sharedModules = [ homeManager.llm-agents ];

        environment = {
          systemPackages = [
            piPackage
            (makeJailedPi { })
            llm-pkgs.claude-code
            (makeJailedClaude { })
            llm-pkgs.claude-desktop
            llm-pkgs.workmux
          ]
          ++ commonPkgs;

          shellAliases = {
            wm = "workmux";
          };

          variables = {
            RTK_TELEMETRY_DISABLED = 1;
            CLAUDE_CONFIG_DIR = "${userHome}/.config/claude";
            CLAUDE_CODE_TMUX_TRUECOLOR = 1;
            CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = 1;
          };
        };

        antob = {

          persistence.home.directories = [
            ".pi"
            ".local/share/rtk"
            ".local/state/workmux"
            ".cache/workmux"
            ".config/Claude"
          ];
        };

        fileSystems = {
          "${userHome}/.pi/agent" = {
            device = "${userHome}/Projects/pi-agent-config";
            options = [ "bind" ];
            fsType = "none";
          };

          # Synced between workstations via Syncthing (~/Projects)
          "${userHome}/.config/claude" = {
            device = "${userHome}/Projects/claude-config";
            options = [ "bind" ];
            fsType = "none";
          };
        };

        # Lets agents sign commits without a YubiKey touch; Claude reads it via GIT_CONFIG_* in its settings.json, Pi via its wrapper
        sops.secrets.agent_signing_key = {
          sopsFile = ../../hosts/common/secrets.yaml;
          owner = user;
          mode = "0400";
        };

        systemd.tmpfiles.rules = [
          "d ${userHome}/.pi 0755 ${user} ${group} -"
          "d ${userHome}/.config/claude 0755 ${user} ${group} -"
        ];
      };
    };

  flake.modules.homeManager.llm-agents =
    { config, lib, ... }:
    {
      programs.git.settings.gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
      xdg.configFile."git/allowed_signers".text = ''
        tobias.lindholm@antob.se ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILw/NZaQAbkoZM/bHDzb3PHJmFYuDU2SkN8XkRvr/I+Y agent
      '';

      xdg.configFile."workmux/config.yaml".text = /* yaml */ ''
        nerdfont: true
        status_icons:
          waiting: "󰭹"
          done: "󰗠"
        status_format: false
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
            - .envrc.local
            - .env
          symlink:
            - node_modules
            - .devenv
            - .venv
        post_create:
          - direnv allow
          - direnv exec . true
        auto_update_check: false
        sidebar:
          width: 40
          sort: window
      '';
    };

}

{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

with lib;
let
  cfg = config.antob.apps.vscode;
in
{
  options.antob.apps.vscode = with types; {
    enable = mkEnableOption "Enable VSCode";
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      inputs.nix-vscode-extensions.overlays.default
    ];

    antob.persistence.home.directories = [
      ".config/Code"
      ".vscode"
    ];

    antob.home.extraOptions.programs.vscode = {
      enable = true;
      package = pkgs.vscode.fhs;

      profiles.default = {
        keybindings = [
          {
            key = "ctrl+shift+d";
            command = "-workbench.view.debug";
            when = "viewContainer.workbench.view.debug.enabled";
          }
          {
            key = "ctrl+shift+d";
            command = "editor.action.duplicateSelection";
          }
          {
            key = "alt+i";
            command = "editor.action.revealDefinition";
            when = "editorHasDefinitionProvider && editorTextFocus && !isInEmbeddedEditor";
          }
          {
            key = "f12";
            command = "-editor.action.revealDefinition";
            when = "editorHasDefinitionProvider && editorTextFocus && !isInEmbeddedEditor";
          }
          {
            key = "alt+o";
            command = "workbench.action.navigateBack";
            when = "canNavigateBack";
          }
          {
            key = "ctrl+alt+-";
            command = "-workbench.action.navigateBack";
            when = "canNavigateBack";
          }
          {
            key = "shift+tab";
            command = "outdent";
            when = "editorTextFocus && !editorReadonly && !editorTabMovesFocus && !inlineSuggestionVisible";
          }
        ];

        userSettings = {
          workbench = {
            colorTheme = "One Dark Pro";
            startupEditor = "none";
            tree.enableStickyScroll = false;
          };

          window = {
            titleBarStyle = "custom";
            menuBarVisibility = "toggle";
            confirmBeforeClose = "always";
            zoomLevel = 1;
          };

          editor = {
            fontFamily = "'Hack Nerd Font', 'monospace', monospace";
            formatOnSave = true;
            stickyScroll.enabled = false;
            inlineSuggest.enabled = true;
            acceptSuggestionOnCommitCharacter = false;
          };

          chat = {
            experimental.statusIndicator.enabled = true;
            agent.enabled = false;
          };

          files = {
            insertFinalNewline = true;
            associations = {
              "*.env*" = "plaintext";
            };
          };

          extensions = {
            autoCheckUpdates = false;
            ignoreRecommendations = true;
            autoUpdate = false;
          };

          update.mode = "none";

          search.exclude = {
            "**/coverage" = true;
            "**/.devenv" = true;
            "**/.direnv" = true;
          };

          "[json]" = {
            editor.defaultFormatter = "vscode.json-language-features";
          };

          "[csharp]" = {
            editor.defaultFormatter = "csharpier.csharpier-vscode";
          };

          "[javascript]" = {
            editor.defaultFormatter = "vscode.typescript-language-features";
          };

          "[jsonc]" = {
            editor.defaultFormatter = "vscode.json-language-features";
          };

          "[ruby]" = {
            editor.defaultFormatter = "testdouble.vscode-standard-ruby";
          };

          "[nix]" = {
            editor.defaultFormatter = "jnoortheen.nix-ide";
          };

          "[python]" = {
            editor.defaultFormatter = "ms-python.black-formatter";
          };

          diffEditor.ignoreTrimWhitespace = false;

          html.format = {
            wrapAttributes = "force-expand-multiline";
            templating = true;
            maxPreserveNewLines = 2;
            wrapLineLength = 120;
          };

          telemetry = {
            telemetryLevel = "off";
            feedback.enabled = false;
          };

          # Installed extensions config
          rust-analyzer.check.command = "clippy";
          gitlens.telemetry.enabled = false;
          dotnetAcquisitionExtension.enableTelemetry = false;
          svelte.enable-ts-plugin = true;
          git.suggestSmartCommit = false;

          nix = {
            formatterPath = "nixfmt";
            enableLanguageServer = true;
            serverPath = "nil";
            serverSettings.nil = {
              formatting = {
                command = [ "nixfmt" ];
              };
            };
          };

          rubyLsp = {
            formatter = "standard";
            rubyVersionManager = {
              identifier = "none";
            };
          };

          gitlens = {
            launchpad.indicator.enabled = false;
            ai.enabled = false;
          };

          vs64.showWelcome = false;

          python.experiments.enabled = false;

          # Disable Copilot everywhere
          github.copilot.enable = {
            "*" = false;
          };

          llama-vscode = {
            ask_install_llamacpp = false;
            ask_upgrade_llamacpp_hours = 72000;
            env_start_last_used = true;
            tool_run_terminal_command_enabled = false;
            env_start_last_used_confirm = false;
            envs_list = [
              {
                name = "Local Environment";
                description = "Everything local";
                completion = {
                  name = "Qwen2.5-Coder-7B-Q8_0-GGUF";
                  # localStartCommand = "llama-server --fim-qwen-7b-default -ngl 99 --port 8012";
                  endpoint = "http://desktob.antob.net:8012";
                  aiModel = "";
                  isKeyRequired = false;
                };
                chat = {
                  name = "Qwen2.5-Coder-7B-Instruct-Q8_0-GGUF";
                  # localStartCommand = "llama-server -hf ggml-org/Qwen2.5-Coder-7B-Instruct-Q8_0-GGUF -ngl 99 -ub 1024 -b 1024 --ctx-size 0 --cache-reuse 256 -np 2 --port 8011";
                  endpoint = "http://desktob.antob.net:8011";
                };
                embeddings = {
                  name = "Nomic-Embed-Text-V2-GGUF";
                  # localStartCommand = "llama-server -hf ggml-org/Nomic-Embed-Text-V2-GGUF -ngl 99 -ub 2048 -b 2048 --ctx-size 2048 --embeddings --port 8010";
                  endpoint = "http://desktob.antob.net:8010";
                };
                tools = {
                  name = "OpenAI gpt-oss 20B";
                  # localStartCommand = "llama-server -hf ggml-org/gpt-oss-20b-GGUF -c 0 --jinja --reasoning-format none -np 2 --port 8009";
                  endpoint = "http://desktob.antob.net:8009";
                  aiModel = "";
                  isKeyRequired = false;
                };
              }
            ];
          };
        };

        extensions = with pkgs.vscode-marketplace; [
          zhuangtongfa.material-theme # One Dark Pro
          tamasfe.even-better-toml
          # vadimcn.vscode-lldb
          jnoortheen.nix-ide
          rust-lang.rust-analyzer
          dotjoshjohnson.xml
          kennylong.kubernetes-yaml-formatter
          shd101wyy.markdown-preview-enhanced
          formulahendry.auto-close-tag
          # ms-dotnettools.csharp
          csharpier.csharpier-vscode
          eamodio.gitlens
          testdouble.vscode-standard-ruby
          aliariff.vscode-erb-beautify
          sleistner.vscode-fileutils
          vortizhe.simple-ruby-erb
          jeff-hykin.better-csv-syntax
          shopify.ruby-lsp
          # ms-dotnettools.vscode-dotnet-runtime
          esbenp.prettier-vscode
          mquandalle.graphql
          ms-python.python
          ms-python.black-formatter
          ggml-org.llama-vscode
        ];
      };
    };

    environment.systemPackages = with pkgs; [
      nixfmt-rfc-style
      nil
    ];
  };
}

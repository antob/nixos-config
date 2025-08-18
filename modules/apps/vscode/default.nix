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
  extensions = inputs.nix-vscode-extensions.extensions.${pkgs.system};
in
{
  options.antob.apps.vscode = with types; {
    enable = mkEnableOption "Enable VSCode";
  };

  config = mkIf cfg.enable {
    antob.persistence.home.directories = [
      ".config/Code"
      ".vscode"
      ".continue" # Config for vscode extension `continue`
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

          diffEditor.ignoreTrimWhitespace = false;

          html.format = {
            wrapAttributes = "force-expand-multiline";
            templating = true;
            maxPreserveNewLines = 2;
            wrapLineLength = 120;
          };

          telemetry.telemetryLevel = "off";

          # Installed extensions config
          rust-analyzer.check.command = "clippy";
          redhat.telemetry.enabled = false;
          gitlens.telemetry.enabled = false;
          dotnetAcquisitionExtension.enableTelemetry = false;
          svelte.enable-ts-plugin = true;
          git.suggestSmartCommit = false;
          continue = {
            telemetryEnabled = false;
            showInlineTip = false;
          };
          "yaml.schemas" = {
            "file:///home/${config.antob.user.name}/.vscode/extensions/continue.continue/config-yaml-schema.json" =
              [
                ".continue/**/*.yaml"
              ];
          };

          nix = {
            formatterPath = "nixfmt";
            enableLanguageServer = true;
            serverPath = "nixd";
            serverSettings.nixd = {
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

          gitlens.launchpad.indicator.enabled = false;

          vs64.showWelcome = false;
        };

        extensions = with extensions.vscode-marketplace; [
          zhuangtongfa.material-theme # One Dark Pro
          tamasfe.even-better-toml
          # vadimcn.vscode-lldb
          jnoortheen.nix-ide
          rust-lang.rust-analyzer
          dotjoshjohnson.xml
          redhat.vscode-yaml
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
          continue.continue
        ];
      };
    };

    environment.systemPackages = with pkgs; [
      nixfmt-rfc-style
      nixd
    ];
  };
}

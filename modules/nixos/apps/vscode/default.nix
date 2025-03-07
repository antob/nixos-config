{
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.apps.vscode;
  extensions = inputs.nix-vscode-extensions.extensions.${system};
in
{
  options.antob.apps.vscode = with types; {
    enable = mkEnableOption "Enable VSCode";
  };

  config = mkIf cfg.enable {
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
          # Use right arrow to accept inline suggestions
          {
            key = "right";
            command = "editor.action.inlineSuggest.commit";
            when = "inlineEditIsVisible && tabShouldAcceptInlineEdit && !editorHoverFocused && !editorTabMovesFocus && !suggestWidgetVisible || inlineSuggestionHasIndentationLessThanTabSize && inlineSuggestionVisible && !editorHoverFocused && !editorTabMovesFocus && !suggestWidgetVisible || inlineEditIsVisible && inlineSuggestionHasIndentationLessThanTabSize && inlineSuggestionVisible && !editorHoverFocused && !editorTabMovesFocus && !suggestWidgetVisible || inlineEditIsVisible && inlineSuggestionVisible && tabShouldAcceptInlineEdit && !editorHoverFocused && !editorTabMovesFocus && !suggestWidgetVisible";
          }
          {
            key = "tab";
            command = "-editor.action.inlineSuggest.commit";
            when = "inlineEditIsVisible && tabShouldAcceptInlineEdit && !editorHoverFocused && !editorTabMovesFocus && !suggestWidgetVisible || inlineSuggestionHasIndentationLessThanTabSize && inlineSuggestionVisible && !editorHoverFocused && !editorTabMovesFocus && !suggestWidgetVisible || inlineEditIsVisible && inlineSuggestionHasIndentationLessThanTabSize && inlineSuggestionVisible && !editorHoverFocused && !editorTabMovesFocus && !suggestWidgetVisible || inlineEditIsVisible && inlineSuggestionVisible && tabShouldAcceptInlineEdit && !editorHoverFocused && !editorTabMovesFocus && !suggestWidgetVisible";
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
            wrapAttributes = "preserve-aligned";
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

          github.copilot = {
            enable = {
              "*" = true;
              plaintext = false;
              yaml = false;
              markdown = false;
              scminput = false;
            };
          };

          vs64.showWelcome = false;
        };

        extensions = with extensions.vscode-marketplace; [
          zhuangtongfa.material-theme # One Dark Pro
          tamasfe.even-better-toml
          vadimcn.vscode-lldb
          jnoortheen.nix-ide
          rust-lang.rust-analyzer
          dotjoshjohnson.xml
          redhat.vscode-yaml
          shd101wyy.markdown-preview-enhanced
          formulahendry.auto-close-tag
          # ms-dotnettools.csharp
          csharpier.csharpier-vscode
          github.copilot
          # github.copilot-chat
          eamodio.gitlens
          testdouble.vscode-standard-ruby
          aliariff.vscode-erb-beautify
          sleistner.vscode-fileutils
          vortizhe.simple-ruby-erb
          jeff-hykin.better-csv-syntax
          shopify.ruby-lsp
          # ms-dotnettools.vscode-dotnet-runtime
          esbenp.prettier-vscode
          svelte.svelte-vscode
          # Forked rosc.vs64 to change comments from ";" to "//" for KickAssembler
          pkgs.antob.vscode-extension-vs64
        ];
      };
    };

    environment.systemPackages = with pkgs; [
      nixfmt-rfc-style
      nixd
    ];
  };
}

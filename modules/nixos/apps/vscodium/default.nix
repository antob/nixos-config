{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.apps.vscodium;
  jsonFormat = pkgs.formats.json { };
in
{
  options.antob.apps.vscodium = with types; {
    enable = mkEnableOption "Enable VSCodium";
  };

  config = mkIf cfg.enable {
    # environment.shellAliases = { code = "codium"; };
    antob.persistence.home.directories = [
      ".config/VSCodium"
      ".vscode-oss"
    ];

    antob.home.extraOptions.home.file = {
      ".config/VSCodium/User/settings.json".source = jsonFormat.generate "vscode-user-settings" {
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
        };

        files = {
          insertFinalNewline = true;
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

        diffEditor.ignoreTrimWhitespace = false;

        "[json]" = {
          editor.defaultFormatter = "vscode.json-language-features";
        };

        "[javascript]" = {
          editor.defaultFormatter = "vscode.typescript-language-features";
        };

        # Installed extensions config
        rust-analyzer.check.command = "clippy";
        redhat.telemetry.enabled = false;

        nix = {
          formatterPath = "nixfmt";
          enableLanguageServer = true;
          serverPath = "nixd";
          serverSettings.nixd = {
            formatting = {
              command = "nixfmt";
            };
          };
        };
      };

      ".config/VSCodium/User/keybindings.json".source = jsonFormat.generate "vscode-keybindings" [
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
    };

    environment.systemPackages = with pkgs; [
      nixfmt-rfc-style
      nixd
      (vscode-with-extensions.override {
        vscode = vscodium;
        vscodeExtensions =
          with vscode-extensions;
          [
            zhuangtongfa.material-theme
            tamasfe.even-better-toml
            vadimcn.vscode-lldb
            jnoortheen.nix-ide
            rust-lang.rust-analyzer
            dotjoshjohnson.xml
            redhat.vscode-yaml
            shd101wyy.markdown-preview-enhanced
            formulahendry.auto-close-tag
          ]
          ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
            {
              name = "vscode-standard-ruby";
              publisher = "testdouble";
              version = "0.0.16";
              sha256 = "sha256-XxL8rEmlI2pCw9YxqcgazUMbC1IL/C8d2zrAvy8tVbU=";
            }
            {
              name = "vscode-erb-beautify";
              publisher = "aliariff";
              version = "0.4.1";
              sha256 = "sha256-BH6sz/vKeYxjnoKum+jY+tzKfxWtHp8WkZn6xyYumvM=";
            }
            {
              name = "vscode-fileutils";
              publisher = "sleistner";
              version = "3.10.3";
              sha256 = "sha256-v9oyoqqBcbFSOOyhPa4dUXjA2IVXlCTORs4nrFGSHzE=";
            }
            {
              name = "simple-ruby-erb";
              publisher = "vortizhe";
              version = "0.2.1";
              sha256 = "sha256-JZov46QWUHIewu4FZtlQL/wRV6rHpu6Kd9yuWdCL77w=";
            }
            {
              name = "better-csv-syntax";
              publisher = "jeff-hykin";
              version = "0.0.2";
              sha256 = "sha256-lNOESQgMwtjM7eTD8KQLWATktF2wjZzdpTng45i05LI=";
            }
            {
              name = "ruby-lsp";
              publisher = "shopify";
              version = "0.8.12";
              sha256 = "sha256-Ab8mn93uA5enm8imD6pU8xMK0fgh2rYeblOhbkUhDrY=";
            }
          ];
      })
    ];
  };
}

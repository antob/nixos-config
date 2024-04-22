{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
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
    antob.persistence.home.directories = [ ".config/VSCodium" ".vscode-oss" ];

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

        extensions = {
          autoCheckUpdates = false;
          ignoreRecommendations = true;
          autoUpdate = false;
        };

        update.mode = "none";

        search.exclude = {
          "**/coverage" = true;
        };

        rust-analyzer.check.command = "clippy";
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
      (vscode-with-extensions.override {
        vscode = vscodium;
        vscodeExtensions = with vscode-extensions; [
          zhuangtongfa.material-theme
          tamasfe.even-better-toml
          vadimcn.vscode-lldb
          jnoortheen.nix-ide
          rust-lang.rust-analyzer
          dotjoshjohnson.xml
          ms-dotnettools.csharp
        ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
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
            name = "solargraph";
            publisher = "castwide";
            version = "0.24.1";
            sha256 = "sha256-M96kGuCKo232rIwLovDU+C/rhEgZWT4s/zsR7CUYPnk=";
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
        ];
      })
    ];
  };
}

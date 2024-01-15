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
    environment.shellAliases = { code = "codium"; };
    antob.persistence.home.directories = [ ".config/VSCodium" ".vscode-oss" ];

    antob.home.extraOptions.home.file = {
      ".config/VSCodium/User/settings.json".source = jsonFormat.generate "vscode-user-settings" {
        window.menuBarVisibility = "toggle";
        workbench.colorTheme = "One Dark Pro";
        editor.fontFamily = "'Hack Nerd Font', 'monospace', monospace";
        editor.formatOnSave = true;
        window.zoomLevel = 1;
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
      ];
    };

    environment.systemPackages = with pkgs; [
      (vscode-with-extensions.override {
        vscode = vscodium;
        vscodeExtensions = with vscode-extensions; [
          zhuangtongfa.material-theme
          bungcip.better-toml
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
        ];
      })
    ];
  };
}

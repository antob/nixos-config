{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.antob.cli-apps.neovim.plugins.copilotLua;
in
{
  options.antob.cli-apps.neovim.plugins.copilotLua = with types; {
    enable = mkBoolOpt true "Whether or not to install and configure copilot-lua.";
    enableAtStartup = mkBoolOpt true "Whether to start with inline suggestions enabled (maps to suggestion.enabled).";
  };

  config = mkIf (cfg.enable && !config.antob.cli-apps.neovim.minimal) {
    antob.home.extraOptions.programs.neovim = {
      plugins = with pkgs.vimPlugins; [
        copilot-lua
      ];

      initLua = lib.mkOrder 200 /* lua */ ''
        require("copilot").setup({
          panel = {
            enabled = false,
          },
          suggestion = {
            enabled = ${boolToString cfg.enableAtStartup},
            auto_trigger = true,
            hide_during_completion = true,
            debounce = 15,
            trigger_on_accept = true,
            suggestion_notification = nil,
            keymap = {
              accept = "<S-Tab>",
              accept_word = "<M-C-Right>",
              accept_line = "<M-Right>",
              next = "<M-]>",
              prev = "<M-[>",
              dismiss = "<C-e>",
            },
          },
          filetypes = {
            dotenv = false,
          },
          logger = {
            file_log_level = vim.log.levels.INFO,
          },
          server_opts_overrides = {
            settings = {
              telemetry = {
                telemetryLevel = "off",
              },
            },
          },
        })

        local copilot_suggestion = require("copilot.suggestion")
        vim.keymap.set("i", "<C-c>", function()
          if copilot_suggestion.is_visible() then
            copilot_suggestion.dismiss()
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
          else
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
          end
        end, { noremap = true, silent = true, desc = "Dismiss Copilot suggestion and exit insert mode" })
      '';
    };
  };
}

{ config, ... }:
let
  inherit (config.flake.lib) mkBoolOpt;
in
{
  flake.modules.nixos.neovim =
    { lib, ... }:
    with lib;
    {
      options.antob.neovim.plugins.copilotLua = with types; {
        enable = mkBoolOpt true "Whether or not to install and configure copilot-lua.";
        enableAtStartup = mkBoolOpt true "Whether to start with inline suggestions enabled (maps to suggestion.enabled).";
      };

    };

  flake.modules.homeManager.neovim =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    with lib;
    let
      cfg = osConfig.antob.neovim.plugins.copilotLua;
    in
    {
      config = lib.mkMerge [
        (lib.mkIf (cfg.enable && !osConfig.antob.neovim.minimal && !osConfig.antob.neovim.localConfig) ({
          programs.neovim = {
            plugins = with pkgs.vimPlugins; [
              copilot-lua
            ];

            initLua = lib.mkOrder 210 /* lua */ ''
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
        }))
      ];
    };

}

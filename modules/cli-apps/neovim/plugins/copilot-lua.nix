{ pkgs, ... }:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      copilot-lua
    ];

    initLua = /* lua */ ''
      vim.defer_fn(function()
        Snacks.toggle({
          name = "Github Copilot",
          get = function()
            if not vim.g.copilot_enabled then -- HACK: since it's disabled by default the below will throw error
              return false
            end
            return not require("copilot.client").is_disabled()
          end,
          set = function(state)
            if state then
              -- setting up for the very first time
              require("copilot").setup({
                panel = {
                  enabled = false,
                },
                suggestion = {
                  enabled = true,
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
              require("copilot.command").enable()
              vim.g.copilot_enabled = true
            else
              require("copilot.command").disable()
              vim.g.copilot_enabled = false
            end
          end,
        }):map("<leader>ct")
      end, 10)

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
}

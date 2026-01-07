{ pkgs, ... }:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      copilot-lua
    ];

    extraLuaConfig = /* lua */ ''
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
            dismiss = "<C-]>",
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
    '';
  };
}

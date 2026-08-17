{ pkgs, lib, ... }:
with lib;
{
  options.antob.cli-apps.neovim.plugins.llamaVim = with types; {
    enable = mkBoolOpt false "Whether or not to install and configure llama-vim.";
    enableAtStartup = mkBoolOpt false "Whether to enable completion at startup.";
    model = mkOpt str "qwen2.5-coder-7B" "The model to use for completions.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions.programs.neovim = {
      plugins = with pkgs.vimPlugins; [
        llama-vim
        # llama-vim-git
      ];

      initLua = lib.mkOrder 200 /* lua */ ''
        vim.api.nvim_set_hl(0, "llama_hl_fim_hint", { fg = "#787c99", ctermfg = 209 })
        vim.api.nvim_set_hl(0, "llama_hl_fim_info", { fg = "#444b6a", ctermfg = 119 })
        vim.g.llama_config = {
          show_info = false,
          enable_at_startup = true,
          endpoint_fim = "http://localhost:8080/infill",
          model_fim = "qwen2.5-coder-7B",
          keymap_fim_trigger = "<C-F>",
          keymap_fim_accept_word = "<C-B>",
        }

        -- Detect floating windows on BufEnter
        vim.api.nvim_create_autocmd("BufEnter", {
          group = augroup,
          pattern = "*",
          callback = function()
            -- Check if the buffer is in a floating window
            local buftype = vim.bo.buftype
            local is_floating = vim.api.nvim_win_get_config(0).relative ~= ""
            if is_floating or buftype == "prompt" or buftype == "nofile" or buftype == "popup" then
              -- Disable completion (affects plugins like llama.vim if they use completion)
              vim.opt_local.completeopt = { "menu", "menuone", "noselect" }
              vim.opt_local.complete = "" -- Disable completion sources
              vim.cmd("LlamaDisable")
            else
              -- Restore settings for non-floating windows
              vim.opt_local.completeopt = { "menu", "menuone", "noselect" }
              vim.opt_local.complete = ".,w,b,u,t,i"
              vim.cmd("LlamaEnable")
            end
          end,
        })
      '';
    };
  };
}

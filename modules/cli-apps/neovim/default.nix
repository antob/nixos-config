{ options, config, pkgs, lib, ... }:

with lib;
let cfg = config.antob.cli-apps.neovim;
in {
  options.antob.cli-apps.neovim = with types; {
    enable = mkEnableOption "Whether or not to enable neovim.";
  };

  imports = [
    ./keymaps.nix
    ./plugins.nix
    ./telescope.nix
    ./treesitter.nix
    ./nvim-tree.nix
    ./nvim-cmp.nix
    ./lsp.nix
  ];

  config = mkIf cfg.enable {
    environment.variables = { EDITOR = "vim"; };

    antob.home.extraOptions.programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      withRuby = false;
      withPython3 = false;

      extraLuaConfig = ''
        -- [[ Setting options ]]
        -- See `:help vim.o`

        -- Set highlight on search
        vim.o.hlsearch = false

        -- Make line numbers default
        vim.wo.number = true

        -- Set relative line numbers
        vim.o.relativenumber = true

        -- Enable mouse mode
        vim.o.mouse = 'a'

        -- Enable break indent
        vim.o.breakindent = true

        -- Save undo history
        vim.o.undofile = true

        -- Case insensitive searching UNLESS /C or capital in search
        vim.o.ignorecase = true
        vim.o.smartcase = true

        -- Decrease update time
        vim.o.updatetime = 250
        vim.wo.signcolumn = 'yes'

        -- Set colorscheme
        vim.o.termguicolors = true
        vim.cmd [[colorscheme onedark]]
        --vim.cmd [[colorscheme catppuccin-mocha]]

        -- Set completeopt to have a better completion experience
        vim.o.completeopt = 'menuone,noselect'

        -- Timeout settings used by which-key
        vim.o.timeout = true
        vim.o.timeoutlen = 500

        -- Misc settings
        vim.o.cursorline = true
        vim.o.clipboard = "unnamedplus"
        -- vim.o.winbar = "%=%m %f"

        vim.cmd [[ set noswapfile ]]

        -- [[ Basic Keymaps ]]
        -- Set <space> as the leader key
        -- See `:help mapleader`
        --  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
        vim.g.mapleader = ' '
        vim.g.maplocalleader = ' '

        -- [[ Highlight on yank ]]
        -- See `:help vim.highlight.on_yank()`
        local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
        vim.api.nvim_create_autocmd('TextYankPost', {
          callback = function()
            vim.highlight.on_yank()
          end,
          group = highlight_group,
          pattern = '*',
        })
      '';
    };
  };
}

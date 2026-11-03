{ lib, ... }:
{
  programs.neovim.initLua = lib.mkOrder 200 /* lua */ ''
    -- keymap helpers
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
    end
    local function nosmap(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = false })
    end
    local function expmap(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { expr = true, desc = desc, silent = true })
    end
  '';
}

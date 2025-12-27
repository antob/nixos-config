{ lib, ... }:
{
  programs.neovim.extraLuaConfig = lib.mkOrder 200 /* lua */ ''
    -- keymap helper
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
    end
  '';
}

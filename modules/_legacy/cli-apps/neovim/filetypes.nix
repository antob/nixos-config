{ ... }:
{
  programs.neovim.initLua = /* lua */ ''
    -- Dotenv filetype
    vim.filetype.add({
      extension = {
        env = "dotenv",
      },
      filename = {
        [".env"] = "dotenv",
        ["env"] = "dotenv",
      },
      pattern = {
        ["[jt]sconfig.*.json"] = "jsonc",
        ["%.env%.[%w_.-]+"] = "dotenv",
      },
    })

    -- Tmux config filetype
    vim.filetype.add({
      extension = {
        tmux = "tmux",
      },
    })
  '';
}

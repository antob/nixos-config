{
  flake.modules.homeManager.neovim =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    {
      config = lib.mkMerge [
        (lib.mkIf (!osConfig.antob.neovim.localConfig) {
          programs.neovim = {
            plugins = with pkgs.vimPlugins; [
              quicker-nvim
            ];

            initLua = lib.mkOrder 212 /* lua */ ''
              vim.keymap.set("n", "<leader>q", function()
                require("quicker").toggle()
              end, {
                desc = "Toggle quickfix",
              })
              vim.keymap.set("n", "<leader>l", function()
                require("quicker").toggle({ loclist = true })
              end, {
                desc = "Toggle loclist",
              })
              require("quicker").setup({
                keys = {
                  {
                    ">",
                    function()
                      require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
                    end,
                    desc = "Expand quickfix context",
                  },
                  {
                    "<",
                    function()
                      require("quicker").collapse()
                    end,
                    desc = "Collapse quickfix context",
                  },
                },
              })
            '';
          };
        })
      ];
    };

}

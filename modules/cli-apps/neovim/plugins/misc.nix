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
        (lib.mkIf (!osConfig.antob.neovim.localConfig) ({
          programs.neovim = {
            plugins = with pkgs.vimPlugins; [
              nvim-ts-autotag
              vim-eunuch
              comment-nvim
            ];

            initLua = lib.mkOrder 206 /* lua */ ''
              require("nvim-ts-autotag").setup({})
              require("Comment").setup()
            '';
          };
        }))
      ];
    };

}

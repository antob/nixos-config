{ pkgs, ... }:
{
  extraPlugins = [
    (pkgs.vimPlugins.llama-vim.overrideAttrs (old: {
      pname = "llama.nvim";
    }))

    # (pkgs.vimUtils.buildVimPlugin {
    #   pname = "llama.nvim";
    #   version = "2025-01-24";
    #   src = pkgs.fetchFromGitHub {
    #     owner = "ggml-org";
    #     repo = "llama.vim";
    #     rev = "81e6802ebd00f177a8db73d62c7eeaf14a30819a";
    #     sha256 = "0fcg0xmdjc9z25ssjmg9pl5q0vk1h1k65ipd4dfzxchvmfzirl5j";
    #   };
    #   meta.homepage = "https://github.com/ggml-org/llama.vim";
    # })
  ];

  extraConfigLua = ''
    vim.g.llama_config = {
      endpoint = "http://desktob.antob.net:8012/infill",
      show_info = 1,
    }

    -- require("llama")
  '';
}

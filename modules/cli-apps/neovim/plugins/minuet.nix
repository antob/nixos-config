{ pkgs, ... }:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      minuet-ai-nvim
    ];

    initLua = /* lua */ ''
      require("minuet").setup({
        provider = "openai_fim_compatible",
        n_completions = 3,
        context_window = 16000,
        provider_options = {
          openai_fim_compatible = {
            api_key = "TERM",
            name = "Llama.cpp",
            end_point = "http://localhost:8012/v1/completions",
            model = "PLACEHOLDER",
            optional = {
              max_tokens = 56,
              top_p = 0.9,
            },
            template = {
              prompt = function(context_before_cursor, context_after_cursor, _)
                return "<|fim_prefix|>"
                  .. context_before_cursor
                  .. "<|fim_suffix|>"
                  .. context_after_cursor
                  .. "<|fim_middle|>"
              end,
              suffix = false,
            },
          },
        },
      })
    '';
  };
}

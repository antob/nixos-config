-- ## LSP config
local configs = require "nvchad.configs.lspconfig"

local servers = {
  nixd = {},
  bashls = {},
  emmet_language_server = {},
  ruby_lsp = {
    cmd = { "bundle", "exec", "ruby-lsp" },
    single_file_support = false,
    init_options = {
      formatter = "standard",
      linters = { "standard" },
    },
  },
  rust_analyzer = {
    settings = {
      ["rust-analyzer"] = {
        diagnostics = {
          enable = true;
        }
      }
    }
  }
}

for name, opts in pairs(servers) do
  opts.on_init = configs.on_init
  opts.capabilities = configs.capabilities
  opts.on_attach = configs.on_attach
  -- opts.on_attach = function(client, bufnr)
  --   configs.on_attach(client, bufnr)
  --   vim.lsp.inlay_hint.enable(true)
  --   if client.server_capabilities.inlayHintProvider then
  --     vim.g.inlay_hints_visible = true

  --     vim.lsp.inlay_hint.enable(true)
  --   else
  --     print("no inlay hints available")
  --   end
	-- end

  require("lspconfig")[name].setup(opts)
end

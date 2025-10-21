local lsp_helpers = require("plugins.lsp.helpers")

vim.lsp.config("lua_ls", {
  capabilities = lsp_helpers.get_capabilities(),
  on_attach = lsp_helpers.get_on_attach(),
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
    },
  },
})

return { "lua_ls" }


local lsp = "rust_analyzer"
local lsp_helpers = require("plugins.lsp.helpers")

vim.lsp.config(lsp, {
  capabilities = lsp_helpers.get_capabilities(),
  on_attach = lsp_helpers.get_on_attach(),
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
      },
      checkOnSave = true,
      check = {
        command = "clippy",
      },
    },
  },
})

return { lsp }

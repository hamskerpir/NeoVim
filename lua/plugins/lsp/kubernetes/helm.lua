local lsp_helpers = require("plugins.lsp.helpers")

vim.lsp.config("helm_ls", {
  on_attach = lsp_helpers.get_on_attach(),
  settings = {
    ["helm-ls"] = {
      yamlls = {
        path = "yaml-language-server",
        yaml = {
          schemas = {
            [require("kubernetes").yamlls_schema()] = "*.yaml",
          },
        },
      },
    },
  },
})

return { "helm_ls" }


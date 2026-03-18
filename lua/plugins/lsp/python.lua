local lsp = "ty"
-- local lsp = "pyright"
-- local lsp = "ruff"

local linter = "ruff"
-- local linter = "pylint"

local formatter = "black"

local lsp_helpers = require("plugins.lsp.helpers")

vim.lsp.config(lsp, {
  on_attach = lsp_helpers.get_on_attach(),
  root_dir = vim.fs.root(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p"), { "pyproject.toml" }),
})

return { lsp }


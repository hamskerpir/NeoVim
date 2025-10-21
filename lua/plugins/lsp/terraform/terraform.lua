local lsp_helpers = require("plugins.lsp.helpers")

vim.lsp.config("terraformls", {
  on_attach = lsp_helpers.get_on_attach(),
  filetypes = { "terraform", "terraform-vars" },
  root_dir = vim.fs.root(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p"), { ".terraform", ".git" }),
})

return { "terraformls" }


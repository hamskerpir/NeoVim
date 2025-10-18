local opt = vim.opt

opt.expandtab = true
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.clipboard = "unnamedplus"
opt.signcolumn = "yes"

vim.keymap.set({ "i", "n", "v" }, "<C-c>", "<Esc>", { desc = "Make Ctrl+C behave like Escape" })


vim.diagnostic.config({
  virtual_lines = true,
  virtual_text = {
    prefix = " ",
    spacing = 2,
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.diagnostic.enable(true, { bufnr = args.buf })
  end,
})

local diagnostic_signs = {
  Error = " ",
  Warn = " ",
  Hint = " ",
  Info = " ",
}

for type, icon in pairs(diagnostic_signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end


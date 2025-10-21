local M = {}

M.setup = function ()
  -- string white spaces on save
  vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    vim.cmd [[StripWhitespace]]
  end,
})
end

return M

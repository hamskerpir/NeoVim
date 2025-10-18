local M = {}

M.setup = function()
  -- Set the color for non-current line numbers (dimmed gray, for example)
  vim.api.nvim_set_hl(0, 'LineNr', { fg = '#a83232', bg = 'NONE' })
  -- Set a bright color for the current line number (CursorLineNr)
  vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#FFA500', bold = true })
end

return M

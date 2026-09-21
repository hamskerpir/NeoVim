return {
  "https://github.com/lewis6991/gitsigns.nvim",
  config = function ()
    require('gitsigns').setup {
      numhl      = true,
      linehl     = true,
      current_line_blame = true,
    }
  end
}


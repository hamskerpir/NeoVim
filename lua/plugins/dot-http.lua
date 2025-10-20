return {
  "jellydn/hurl.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    -- Optional, for markdown rendering with render-markdown.nvim
    {
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { "markdown" },
      },
      ft = { "markdown" },
    },
  },
  ft = "hurl",
  opts = {
    debug = false,
    show_notification = false,
    mode = "split",
    -- Default formatter
    formatters = {
      json = { 'jq' },
    }
  }
}

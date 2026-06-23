return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      "smartpde/telescope-recent-files",
      "nvim-telescope/telescope-project.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
    },
    opts = function()
      local themes = require("telescope.themes")
      return {
        defaults = {
          preview = {
            treesitter = false,
          },
        },
        extensions = {
          ["ui-select"] = themes.get_dropdown(),
        },
      }
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      telescope.load_extension("ui-select")
      telescope.load_extension("recent_files")
      telescope.load_extension('project')

      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "Search: Files" })
      vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "Search: Live grep" })
    end,
  },
}

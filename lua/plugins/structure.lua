return {
	"stevearc/aerial.nvim",
	opts = {},
	-- Optional dependencies
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
  config = function()
		require("aerial").setup(
      {
        autojump = true,
        close_on_select = true,
        nav = {
          min_height = { 30, 0.3 },
          min_width = { 0.4, 40 },
          -- Jump to symbol in source window when the cursor moves
          autojump = true,
          -- Show a preview of the code in the right column, when there are no child symbols
          preview = true,
          keymaps = {
            ["<CR>"] = "actions.jump",
            ["<2-LeftMouse>"] = "actions.jump",
            ["<C-v>"] = "actions.jump_vsplit",
            ["<C-s>"] = "actions.jump_split",
            ["<Left>"] = "actions.left",
            ["<Right>"] = "actions.right",
            ["<C-c>"] = "actions.close",
          }
        }
      }
    )
  end
}

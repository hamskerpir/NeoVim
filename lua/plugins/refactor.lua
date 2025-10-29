return {
	"ThePrimeagen/refactoring.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		require("refactoring").setup({
			prompt_func_return_type = {
				go = true,
				python = true,
			},
			prompt_func_param_type = {
				go = true,
				python = true,
			},
			printf_statements = {},
			print_var_statements = {},
			show_success_message = false,
		})
	end,
}

local lsp_helpers = require("plugins.lsp.helpers")

return {
	"mistweaverco/kulala.nvim",
	dependencies = {
		{
			"nvim-treesitter/nvim-treesitter",
			opts = function(_, opts)
				opts.ensure_installed = opts.ensure_installed or {}
				vim.list_extend(opts.ensure_installed, { "http", "xml" })
			end,
		},
	},
	ft = { "http", "rest" },
	opts = {
		global_keymaps = false,
		global_keymaps_prefix = "<leader>R",
		kulala_keymaps_prefix = "",
		ui = {
			display_mode = "split",
		},
		lsp = {
			enable = true,
			filetypes = { "http", "rest" },
			keymaps = false,
			formatter = {
				split_params = 4, -- split query/form parameters onto multiple lines if number of params exceeds this value
				sort = { -- enable/disable alphabetical sorting
					metadata = true,
					variables = true,
					commands = false,
					json = true,
				},
				quote_json_variables = true, -- add quotes around {{variable}} in JSON bodies
				indent = 2, -- base indentation for scripts
			},
			on_attach = lsp_helpers.get_on_attach(),
		},
	},
}

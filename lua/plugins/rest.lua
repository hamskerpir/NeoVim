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
	keys = {
		{
			"<leader>Rs",
			function()
				require("kulala").run()
			end,
			desc = "Send request",
		},
		{
			"<leader>Ra",
			function()
				require("kulala").run_all()
			end,
			desc = "Send all requests",
		},
		{
			"<leader>Rb",
			function()
				require("kulala").scratchpad()
			end,
			desc = "Open scratchpad",
		},
		{
			"<leader>Rt",
			function()
				require("kulala").toggle_view()
			end,
			desc = "Toggle headers/body",
		},
	},
	opts = {
		global_keymaps = false,
		global_keymaps_prefix = "<leader>R",
		kulala_keymaps_prefix = "",
	},
}

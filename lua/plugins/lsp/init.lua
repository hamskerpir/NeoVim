local deps = {
	"plugins.lsp.lua",
	"plugins.lsp.python",
	"plugins.lsp.harper",
	"plugins.lsp.kubernetes.helm",
	-- "plugins.lsp.terraform.hcl",
	"plugins.lsp.terraform.terraform",
}

return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		event = "VeryLazy",
		opts = {
			servers = {
				terraformls = {},
				hcl = {},
				tflint = {},
			},
		},
		config = function()
			require("mason").setup()
			local mason_lspconfig = require("mason-lspconfig")

			local mod_deps = {}
			-- iterate over all submodules
			for _, mod in ipairs(deps) do
				-- get their dependencies
				local mod_d = require(mod)
				-- iterate over each dependency to insert it in pool
				for _, d in ipairs(mod_d) do
					table.insert(mod_deps, d)
				end
			end

			mason_lspconfig.setup({
				automatic_installation = true,
				ensure_installed = mod_deps,
			})
		end,
	},
}

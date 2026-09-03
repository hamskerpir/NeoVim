local deps = {
	"plugins.lsp.lua",
	"plugins.lsp.python",
	"plugins.lsp.go",
	--"plugins.lsp.ruby",
	"plugins.lsp.javascript",
	"plugins.lsp.vue",
	--	"plugins.lsp.harper",
	"plugins.lsp.kubernetes.helm",
	-- "plugins.lsp.terraform.hcl",
	"plugins.lsp.terraform.terraform",
	"plugins.lsp.rust",
}

return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		event = "VeryLazy",
		config = function()
			require("mason").setup()
			local mason_lspconfig = require("mason-lspconfig")
			local mason_tool_installer = require("mason-tool-installer")

			local mod_deps = {}
			for _, mod in ipairs(deps) do
				for _, d in ipairs(require(mod)) do
					table.insert(mod_deps, d)
				end
			end

			mason_lspconfig.setup({
				automatic_installation = true,
				ensure_installed = mod_deps,
				handlers = {
					function(server_name)
						require("lspconfig")[server_name].setup({})
					end,
					-- managed directly via vim.lsp.config + vim.lsp.enable in javascript.lua
					ts_ls = function() end,
					vtsls = function() end,
				},
			})

			-- lspconfig v5 auto-enables ts_ls even with a no-op handler;
			-- disable it now and kill any client that still sneaks through.
			vim.lsp.enable("ts_ls", false)
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client and client.name == "ts_ls" then
						vim.lsp.stop_client(client.id)
					end
				end,
			})

			mason_tool_installer.setup({
				ensure_installed = {
					"prettier",
					"prettierd",
					"xmlformatter",
				},
				run_on_start = true,
			})
		end,
	},
}

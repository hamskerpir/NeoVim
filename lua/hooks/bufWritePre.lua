local M = {}

M.setup = function()
	require("conform").setup({
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "isort", "ruff", "black" },
			rust = { "rustfmt", lsp_format = "fallback" },
			javascript = { "prettierd", "prettier", stop_after_first = true },
			vue = { "prettierd", "prettier", stop_after_first = true },
			yaml = { "prettierd" },
			xml = { "xmlformatter" },
		},
	})
	vim.api.nvim_create_autocmd("BufWritePre", {
		pattern = "*",
		callback = function(args)
			-- Strip whitespaces
			vim.cmd([[StripWhitespace]])

			require("conform").format({ bufnr = args.buf })
		end,
	})
end

return M

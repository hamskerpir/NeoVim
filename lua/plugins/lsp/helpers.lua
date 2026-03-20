local M = {}

function M.get_on_attach()
	local telescope = require("telescope.builtin")
	return function(_, bufnr)
		local map = function(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc and ("LSP: " .. desc) or nil })
		end

		map("n", "gh", vim.lsp.buf.hover, "Hover documentation")
		map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
		map("n", "gd", vim.lsp.buf.definition, "Go to definition")
		map("n", "gr", telescope.lsp_references, "Find references")
		map("n", "<leader>i", function()
			require("custom_actions").import_actions()
		end, "Import missing")
	end
end

function M.get_capabilities()
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
	if ok_cmp then
		return cmp_nvim_lsp.default_capabilities(capabilities)
	end
	return capabilities
end

return M

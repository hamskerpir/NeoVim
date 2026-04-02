local lsps = {
	"vue_ls",
}

local lsp_helpers = require("plugins.lsp.helpers")

-- Define the root markers appropriate for Vue projects
local root_files = { "package.json", "tsconfig.json", "jsconfig.json", ".git", "vite.config.ts", "vite.config.js" }

for _, server in ipairs(lsps) do
	vim.lsp.config(server, {
		on_attach = lsp_helpers.get_on_attach(),
		root_dir = function(fname)
			return vim.fs.root(fname, root_files)
		end,
	})
end

return lsps

local lsps = {
	"vue_ls",
}

local lsp_helpers = require("plugins.lsp.helpers")

-- Define the root markers appropriate for Vue projects
local root_files = { "package.json", "tsconfig.json", "jsconfig.json", ".git", "vite.config.ts", "vite.config.js" }

-- Note: nvim-lspconfig already provides cmd, filetypes = { "vue" }, and the
-- on_init tsserver/request forwarding handler for hybrid mode with vtsls.
for _, server in ipairs(lsps) do
	vim.lsp.config(server, {
		capabilities = lsp_helpers.get_capabilities(),
		on_attach = lsp_helpers.get_on_attach(),
		root_markers = root_files,
	})
	vim.lsp.enable(server)
end

return lsps

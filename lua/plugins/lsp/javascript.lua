local lsps = {
	"ts_ls", -- Handles JavaScript, TypeScript, JSX, and TSX (React)
	"html", -- Handles HTML files
	"cssls", -- Handles CSS and SCSS files (often used over 'css-lsp')
	"tailwindcss", -- Handles Tailwind CSS suggestions and features

	-- Linters and Formatters (often installed by Mason, but configured separately)
	-- While formatters/linters are configured separately, listing them here ensures they are installed:
	-- "eslint_d",            -- Linter (If you use the separate LSP for ESLint)
	-- "prettierd",           -- Formatter (If you use the separate LSP for Prettier)
}

local linter = "eslint"
local formatter = "prettier"

local lsp_helpers = require("plugins.lsp.helpers")

-- Define the root markers appropriate for Node/Frontend projects
local root_files = { "package.json", "tsconfig.json", "jsconfig.json", ".git" }

-- Configure all LSPs using the custom 'vim.lsp.config' function
-- NOTE: This assumes your custom 'vim.lsp.config' handles applying
-- these shared settings correctly to each server based on filetype.
for _, server in ipairs(lsps) do
	local config = {
		on_attach = lsp_helpers.get_on_attach(),
		root_dir = function(fname)
			return vim.fs.root(fname, root_files)
		end,
	}

	-- Add specific settings for 'ts_ls' to support Vue files (Hybrid Mode)
	if server == "ts_ls" then
		local ok_reg, registry = pcall(require, "mason-registry")
		if ok_reg then
			local ok_pkg, vue_package = pcall(registry.get_package, "vue-language-server")
			if ok_pkg and type(vue_package) == "table" and vue_package.is_installed and vue_package:is_installed() then
				local ok_path, vue_plugin_path = pcall(function()
					return vue_package:get_install_path()
						.. "/node_modules/@vue/typescript-plugin"
				end)

				if ok_path then
					config.init_options = {
						plugins = {
							{
								name = "@vue/typescript-plugin",
								location = vue_plugin_path,
								languages = { "vue" },
							},
						},
					}
					config.filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact", "vue" }
				end
			end
		end
	end

	vim.lsp.config(server, config)
end

return lsps

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

-- Calculate the project root directory
local root_dir = vim.fs.root(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p"), root_files)

-- Configure all LSPs using the custom 'vim.lsp.config' function
-- NOTE: This assumes your custom 'vim.lsp.config' handles applying
-- these shared settings correctly to each server based on filetype.
for _, server in ipairs(lsps) do
	vim.lsp.config(server, {
		on_attach = lsp_helpers.get_on_attach(),
		root_dir = root_dir,
	})
end

return lsps

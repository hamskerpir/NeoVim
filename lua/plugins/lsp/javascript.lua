local lsp_helpers = require("plugins.lsp.helpers")

local root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" }

local vtsls_settings = {
	typescript = {
		inlayHints = {
			parameterNames = { enabled = "literals" },
			parameterTypes = { enabled = true },
			variableTypes = { enabled = true },
			propertyDeclarationTypes = { enabled = true },
			functionLikeReturnTypes = { enabled = true },
			enumMemberValues = { enabled = true },
		},
		preferences = { importModuleSpecifier = "non-relative" },
		updateImportsOnFileMove = { enabled = "always" },
	},
	javascript = {
		inlayHints = {
			parameterNames = { enabled = "literals" },
			parameterTypes = { enabled = true },
		},
	},
	vtsls = {
		enableMoveToFileCodeAction = true,
		autoUseWorkspaceTsdk = true, -- use the project's own TypeScript SDK
		experimental = {
			completion = { enableServerSideFuzzyMatch = true },
		},
	},
}

-- attach Vue plugin if vue-language-server is installed (hybrid mode)
local ok_reg, registry = pcall(require, "mason-registry")
if ok_reg then
	local ok_pkg, vue_pkg = pcall(registry.get_package, "vue-language-server")
	if ok_pkg and type(vue_pkg) == "table" and vue_pkg.is_installed and vue_pkg:is_installed() then
		local ok_path, plugin_path = pcall(function()
			return vue_pkg:get_install_path() .. "/node_modules/@vue/typescript-plugin"
		end)
		if ok_path then
			vtsls_settings.vtsls.tsserver = {
				globalPlugins = {
					{
						name = "@vue/typescript-plugin",
						location = plugin_path,
						languages = { "vue" },
						configNamespace = "typescript",
						enableForWorkspaceTypeScriptVersions = true,
					},
				},
			}
		end
	end
end

-- root_markers avoids the old function(fname) pattern which is ignored in Neovim 0.12+
vim.lsp.config("vtsls", {
	on_attach = lsp_helpers.get_on_attach(),
	root_markers = root_markers,
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
	settings = vtsls_settings,
})
vim.lsp.enable("vtsls")

vim.lsp.config("eslint", {
	on_attach = function(_, bufnr)
		vim.api.nvim_create_autocmd("BufWritePre", {
			buffer = bufnr,
			callback = function() pcall(vim.cmd, "EslintFixAll") end,
		})
	end,
	root_markers = {
		".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json",
		"eslint.config.js", "eslint.config.mjs", "package.json",
	},
})

return { "vtsls", "html", "cssls", "tailwindcss", "eslint" }

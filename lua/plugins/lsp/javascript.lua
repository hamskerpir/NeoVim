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

-- Attach @vue/typescript-plugin for Vue 3+ hybrid mode (Mason v2 path)
-- https://github.com/vuejs/language-tools/wiki/Neovim
local mason_packages = (vim.env.MASON and (vim.env.MASON .. "/packages"))
	or (vim.fn.stdpath("data") .. "/mason/packages")
local vue_language_server_path = mason_packages .. "/vue-language-server/node_modules/@vue/language-server"

vtsls_settings.vtsls.tsserver = {
	globalPlugins = {
		{
			name = "@vue/typescript-plugin",
			location = vue_language_server_path,
			languages = { "vue" },
			configNamespace = "typescript",
			enableForWorkspaceTypeScriptVersions = true,
		},
	},
}

local base_on_attach = lsp_helpers.get_on_attach()

-- root_markers avoids the old function(fname) pattern which is ignored in Neovim 0.12+
vim.lsp.config("vtsls", {
	capabilities = lsp_helpers.get_capabilities(),
	on_attach = function(client, bufnr)
		base_on_attach(client, bufnr)
		local existing_capabilities = client.server_capabilities
		if existing_capabilities.semanticTokensProvider then
			if vim.bo[bufnr].filetype == "vue" then
				existing_capabilities.semanticTokensProvider.full = false
			else
				existing_capabilities.semanticTokensProvider.full = true
			end
		end
	end,
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

local opt = vim.opt

opt.expandtab = true
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.clipboard = "unnamedplus"
opt.signcolumn = "yes"

vim.keymap.set({ "i", "n", "v" }, "<C-c>", "<Esc>", { desc = "Make Ctrl+C behave like Escape" })
vim.keymap.set({ "n", "v" }, "<M-CR>", function()
	require("custom_actions").code_actions()
end, { desc = "Code actions & refactoring" })
vim.keymap.set("v", "<C-r>", '"hy:%s/<C-r>h//gc<left><left><left>', { desc = "Search and replace selected text" })
vim.keymap.set("n", "r", "<C-r>", {
	noremap = true,
	silent = true,
	desc = "Redo (was <C-r>)",
})
--- VISUAL ---
vim.keymap.set("x", ">", ">gv", { noremap = true, silent = true, desc = "Indent and Reselect" })
vim.keymap.set("x", "<", "<gv", { noremap = true, silent = true, desc = "Dedent and Reselect" })
vim.keymap.set("x", "<leader>rf", ":Refactor extract ")
vim.keymap.set("x", "<leader>rv", ":Refactor extract_var ")

--- NORMAL ---
vim.keymap.set("n", "q:", "<nop>", { desc = "Disable command-line window" })
vim.keymap.set("n", "q/", "<nop>", { desc = "Disable search history window" })
vim.keymap.set("n", "q?", "<nop>", { desc = "Disable search history window" })
vim.keymap.set("n", "<S-Up>", "<Up>", { desc = "remove unsued" })
vim.keymap.set("n", "<S-Down>", "<Down>", { desc = "remove unsued" })

vim.diagnostic.config({
	-- virtual_lines = true,
	virtual_text = {
		prefix = " ",
		spacing = 2,
	},
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		vim.diagnostic.enable(true, { bufnr = args.buf })
	end,
})

local diagnostic_signs = {
	Error = " ",
	Warn = " ",
	Hint = " ",
	Info = " ",
}

for type, icon in pairs(diagnostic_signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

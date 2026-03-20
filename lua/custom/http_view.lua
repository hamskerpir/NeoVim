local M = {}

M.open_http_view = function()
	local http_file = vim.fn.expand("~/.http/all.http")
	vim.cmd("edit " .. http_file)
	vim.cmd("AerialOpen")
	vim.schedule(function()
		require("kulala").set_selected_env()
	end)
end

M.setup = function()
	vim.api.nvim_create_user_command("HttpView", function()
		M.open_http_view()
	end, { desc = "Open ~/.http/all.http and focus Aerial" })
end

return M

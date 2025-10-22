local M = {}

M.setup = function()
	require("hooks.bufWritePre").setup()
end

return M

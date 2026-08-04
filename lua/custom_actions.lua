local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

-- Helper to execute LSP code action
local function execute_lsp_action(action, client_id)
	local client = vim.lsp.get_client_by_id(client_id)
	if not client then
		return
	end

	-- 1. Apply workspace edits
	if action.edit then
		vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
	end

	-- 2. Execute command with strict validation to prevent crashes
	local cmd_to_exec = nil
	if action.command then
		if type(action.command) == "table" and action.command.command then
			cmd_to_exec = action.command
		end
	elseif action.arguments and action.command then
		cmd_to_exec = action
	end

	if cmd_to_exec then
		vim.lsp.buf.execute_command(cmd_to_exec)
	-- hack for kulala lsp
	elseif action.fn then
		action.fn()
	end
end

-- Helper to request LSP actions synchronously
local function get_lsp_actions(bufnr, range)
	local clients = vim.lsp.get_clients({ bufnr = bufnr })
	if #clients == 0 then
		return {}
	end

	local actions_list = {}
	for _, client in ipairs(clients) do
		local client_params = vim.lsp.util.make_range_params(0, client.offset_encoding)
		if range then
			client_params.range = range
		end

		client_params.context = {
			diagnostics = vim.lsp.diagnostic.get_line_diagnostics(bufnr),
		}

		local response, err = client.request_sync("textDocument/codeAction", client_params, 2000, bufnr)
		if not err and response and response.result then
			for _, action in pairs(response.result) do
				table.insert(actions_list, {
					title = action.title,
					action = action,
					client_id = client.id,
					type = "lsp",
				})
			end
		end
	end

	return actions_list
end

-- Helper to get Refactoring plugin actions
local function get_refactor_actions()
	local has_refactoring = pcall(require, "refactoring")
	if not has_refactoring then
		return {}
	end

	local refactors = {
		{ title = "Extract Function", action = "extract_func" },
		{ title = "Extract Function To File", action = "extract_func_to_file" },
		{ title = "Extract Variable", action = "extract_var" },
		{ title = "Inline Function", action = "inline_func" },
		{ title = "Inline Variable", action = "inline_var" },
	}

	local actions_list = {}
	for _, ref in ipairs(refactors) do
		table.insert(actions_list, {
			title = "[Refactor] " .. ref.title,
			action = ref.action,
			type = "refactor",
		})
	end
	return actions_list
end

-- Helper to get DAP actions
local function get_dap_actions()
	local ok, dap = pcall(require, "dap")
	if not ok then
		return {}
	end

	return {
		{
			title = "[Debug] Set Conditional Breakpoint",
			action = "conditional_breakpoint",
			type = "dap",
		},
	}
end

-- Custom actions
M.fold_all_functions = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local params = { textDocument = vim.lsp.util.make_text_document_params() }

	vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, function(err, result, _, _)
		if err or not result then
			vim.notify("No symbols found to fold", vim.log.levels.INFO)
			return
		end

		local function find_functions(symbols, found)
			for _, symbol in ipairs(symbols) do
				local range = symbol.range or (symbol.location and symbol.location.range)
				if range and (symbol.kind == 6 or symbol.kind == 12) then
					table.insert(found, range)
				end
				if symbol.children then
					find_functions(symbol.children, found)
				end
			end
		end

		local function_ranges = {}
		find_functions(result, function_ranges)

		if #function_ranges == 0 then
			vim.notify("No functions found to fold", vim.log.levels.INFO)
			return
		end

		-- Set foldmethod to manual and clear existing folds
		vim.opt_local.foldmethod = "manual"
		vim.cmd("normal! zE")

		for _, range in ipairs(function_ranges) do
			local start_line = range.start.line + 1
			local end_line = range["end"].line + 1
			-- Only fold if it spans more than one line
			if start_line < end_line then
				local ok, fold_err = pcall(vim.cmd, string.format("%d,%dfold", start_line, end_line))
				if not ok then
					-- Ignore errors if fold already exists or range is invalid
				end
			end
		end
		vim.cmd("normal! zM") -- Close all folds
	end)
end

local function get_custom_actions()
	return {
		{
			title = "[Custom] Fold All Functions",
			action = "fold_all_functions",
			type = "custom",
		},
	}
end

M.code_actions = function(opts)
	opts = opts or {}
	opts = require("telescope.themes").get_cursor(opts)
	local bufnr = vim.api.nvim_get_current_buf()

	local mode = vim.api.nvim_get_mode().mode
	local is_visual = mode:match("[vV\22]") ~= nil

	local refactor_actions = get_refactor_actions()
	local dap_actions = get_dap_actions()
	local custom_actions = get_custom_actions()
	local range = nil

	if is_visual then
		-- Sync escape to set '< and '> marks
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", true)
		local start_pos = vim.fn.getpos("'<")
		local end_pos = vim.fn.getpos("'>")
		range = {
			start = { line = start_pos[2] - 1, character = start_pos[3] - 1 },
			["end"] = { line = end_pos[2] - 1, character = end_pos[3] },
		}
	end

	local lsp_actions = get_lsp_actions(bufnr, range)

	local all_actions = {}
	for _, a in ipairs(lsp_actions) do
		a.title = "[LSP] " .. a.title
		table.insert(all_actions, a)
	end
	for _, a in ipairs(refactor_actions) do
		table.insert(all_actions, a)
	end
	for _, a in ipairs(dap_actions) do
		table.insert(all_actions, a)
	end
	for _, a in ipairs(custom_actions) do
		table.insert(all_actions, a)
	end

	if #all_actions == 0 then
		vim.notify("No code actions available", vim.log.levels.INFO)
		return
	end

	pickers
		.new(opts, {
			prompt_title = "Code Actions & Refactoring",
			finder = finders.new_table({
				results = all_actions,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.title,
						ordinal = entry.title,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)

					if not selection then
						return
					end
					local item = selection.value

					vim.schedule(function()
						if item.type == "lsp" then
							execute_lsp_action(item.action, item.client_id)
						elseif item.type == "refactor" then
							if is_visual then
								-- Reliable visual re-selection + command simulation
								local cmd = string.format("gv:Refactor %s<cr>", item.action)
								vim.api.nvim_input(cmd)
							else
								local keys = require("refactoring")[item.action]()
								if keys then
									vim.api.nvim_input(keys)
								end
							end
						elseif item.type == "dap" then
							if item.action == "conditional_breakpoint" then
								require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
							end
						elseif item.type == "custom" then
							if item.action == "fold_all_functions" then
								M.fold_all_functions()
							end
						end
					end)
				end)
				return true
			end,
		})
		:find()
end

return M

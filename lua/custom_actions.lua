local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

-- Helper to execute LSP code action
local function execute_lsp_action(action, client_id)
  local client = vim.lsp.get_client_by_id(client_id)
  if not client then return end

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
  end
end

-- Helper to request LSP actions synchronously
local function get_lsp_actions(bufnr, range)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then return {} end

  local actions_list = {}
  for _, client in ipairs(clients) do
    local client_params = vim.lsp.util.make_range_params(0, client.offset_encoding)
    if range then client_params.range = range end

    client_params.context = {
      diagnostics = vim.lsp.diagnostic.get_line_diagnostics(bufnr)
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
  local has_refactoring, refactoring = pcall(require, "refactoring")
  if not has_refactoring then return {} end

  local refactors = refactoring.get_refactors()
  local actions_list = {}
  for _, refactor_name in ipairs(refactors) do
    table.insert(actions_list, {
      title = "[Refactor] " .. refactor_name,
      action = refactor_name,
      type = "refactor",
    })
  end
  return actions_list
end

-- Helper to get DAP actions
local function get_dap_actions()
  local ok, dap = pcall(require, "dap")
  if not ok then return {} end

  return {
    {
      title = "[Debug] Set Conditional Breakpoint",
      action = "conditional_breakpoint",
      type = "dap",
    }
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
  for _, a in ipairs(refactor_actions) do table.insert(all_actions, a) end
  for _, a in ipairs(dap_actions) do table.insert(all_actions, a) end

  if #all_actions == 0 then
    vim.notify("No code actions available", vim.log.levels.INFO)
    return
  end

  pickers.new(opts, {
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

        if not selection then return end
        local item = selection.value

        vim.schedule(function()
          if item.type == "lsp" then
            execute_lsp_action(item.action, item.client_id)
          elseif item.type == "refactor" then
            if is_visual then
              -- Reliable visual re-selection + command simulation
              local cmd_name = item.action:lower():gsub(" ", "_"):gsub("variable", "var"):gsub("function", "func")
              -- if cmd_name == "extract_variable" then cmd_name = "extract_var" end

              local cmd = string.format("gv:Refactor %s<cr>", cmd_name)
              vim.api.nvim_input(cmd)
            else
              require("refactoring").refactor(item.action)
            end
          elseif item.type == "dap" then
            if item.action == "conditional_breakpoint" then
              require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
            end
          end
        end)
      end)
      return true
    end,
  }):find()
end

return M

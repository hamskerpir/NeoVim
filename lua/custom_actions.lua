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

  if action.edit or type(action.command) == "table" then
    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
    end
    if type(action.command) == "table" then
      vim.lsp.buf.execute_command(action.command)
    end
  else
    vim.lsp.buf.execute_command(action)
  end
end

-- Helper to request LSP actions synchronously
local function get_lsp_actions(bufnr, range)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then return {} end

  -- Use the first client's offset_encoding as a baseline for the request params
  local offset_encoding = clients[1].offset_encoding
  local params = vim.lsp.util.make_range_params(0, offset_encoding)

  if range then
    params.range = range
  end

  params.context = {
    diagnostics = vim.lsp.diagnostic.get_line_diagnostics(bufnr)
  }

  local actions_list = {}
  -- Request from each client individually to avoid encoding conflicts
  for _, client in ipairs(clients) do
    local client_params = vim.lsp.util.make_range_params(0, client.offset_encoding)
    if range then client_params.range = range end
    client_params.context = params.context

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
  if not has_refactoring then
    return {}
  end

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

-- NEW: Helper to get DAP actions
local function get_dap_actions()
  local ok, dap = pcall(require, "dap")
  if not ok then return {} end

  return {
    {
      title = "[Debug] Set Conditional Breakpoint",
      action = function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end,
      type = "dap",
    }
  }
end

M.import_actions = function(opts)
  opts = opts or {}
  opts = require("telescope.themes").get_cursor(opts)
  local bufnr = vim.api.nvim_get_current_buf()

  local lsp_actions = get_lsp_actions(bufnr)
  local import_actions = {}

  for _, item in ipairs(lsp_actions) do
    local title = item.title:lower()
    local kind = item.action.kind or ""

    -- Filter for common import-related phrases across various LSPs
    -- e.g., "Import 'xxx'", "Add import 'xxx'", "QuickFix: Import 'xxx'"
    if title:match("import") or title:match("add missing") or kind:match("quickfix") then
      table.insert(import_actions, item)
    end
  end

  if #import_actions == 0 then
    vim.notify("No import actions found under cursor", vim.log.levels.INFO)
    return
  end

  pickers.new(opts, {
    prompt_title = "Import Picker",
    finder = finders.new_table({
      results = import_actions,
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
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then return end

        local item = selection.value
        execute_lsp_action(item.action, item.client_id)
      end)
      return true
    end,
  }):find()
end

M.code_actions = function(opts)
  opts = opts or {}
  opts = require("telescope.themes").get_cursor(opts)
  local bufnr = vim.api.nvim_get_current_buf()

  -- Check if we are in visual mode and get the range
  local mode = vim.api.nvim_get_mode().mode
  local range = nil
  if mode == "v" or mode == "V" or mode == " " then
    local _, start_row, start_col, _ = unpack(vim.fn.getpos("v"))
    local _, end_row, end_col, _ = unpack(vim.fn.getpos("."))

    -- Ensure start is before end
    if start_row > end_row or (start_row == end_row and start_col > end_col) then
      start_row, end_row = end_row, start_row
      start_col, end_col = end_col, start_col
    end

    range = {
      start = { line = start_row - 1, character = start_col - 1 },
      ["end"] = { line = end_row - 1, character = end_col - 1 },
    }

    -- Escape visual mode to prevent issues when executing actions
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
  end

  local lsp_actions = get_lsp_actions(bufnr, range)
  local refactor_actions = get_refactor_actions()
  local dap_actions = get_dap_actions()

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
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then return end

        local item = selection.value
        if item.type == "lsp" then
          execute_lsp_action(item.action, item.client_id)
        elseif item.type == "refactor" then
          require("refactoring").refactor(item.action)
        elseif item.type == "dap" then
          item.action()
        end
      end)
      return true
    end,
  }):find()
end

return M

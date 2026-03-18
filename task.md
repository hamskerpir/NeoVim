**Role:** Expert Neovim Lua Developer and LSP Specialist.

**Context:** I have a custom Neovim Lua script that uses Telescope to display LSP code actions in a popup under the cursor. However, I am missing the ability to easily find and insert missing imports (e.g., hovering over `time.time()` and getting a prompt to inject `import time` at the top of the file).

**Objective:**
I need you to implement or fix a Neovim Lua solution that allows me to select and insert missing imports for unresolved variables/functions under my cursor.

**Requirements:**
1. **LSP QuickFix Integration:** Write a Lua function that requests `textDocument/codeAction` specifically filtering for `QuickFix` or import-related actions. If the LSP provides a "Import 'time'" action, it should be presented in a minimal Telescope dropdown (using the `cursor` theme) or `vim.ui.select`.
2. **Handle Multiple Options:** If there are multiple possible imports (e.g., `import time` vs `from datetime import time`), the user must be able to select the correct one from the popup.
3. **Fallback/Plugin Recommendation (Crucial):** If standard LSP code actions are insufficient for this in certain languages (like standard `pyright` in Python, which often lacks auto-import Code Actions compared to `basedpyright` or `pylsp`), explain this limitation. If necessary, provide code to integrate a dedicated import plugin (like `telescope-import.nvim` or `nvim-code-action-menu`) into my existing config.
4. **Execution:** Once the user selects the import from the Telescope/UI picker, the script must correctly apply the `WorkspaceEdit` to inject the import statement at the top of the file.

**Current Setup Context:**
- UI: Telescope (`telescope.pickers`, `telescope.finders`)
- Execution: I already have a helper function `execute_lsp_action(action, client_id)` that processes `action.edit` and `action.command`.

**Deliverable:**
Please provide the specific Lua code to achieve this "Missing Import Picker" and instructions on how to bind it to a keymap (e.g., `<leader>i`). If my current LSP needs to be swapped or configured to emit these specific import actions, please specify those configurations.


you can check that in code_actions.lua file and read and fix whatever you ant in this directory to solve that task.

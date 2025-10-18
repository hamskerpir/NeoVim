return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "mfussenegger/nvim-dap-python"
    },
    config = function()
      local ok_dap, dap = pcall(require, "dap")
      if not ok_dap then
        return
      end

      local ok_dapui, dapui = pcall(require, "dapui")
      local ok_dap_python, dap_python = pcall(require, "dap-python")

      dap.set_log_level("WARN")

      if ok_dapui then
        dapui.setup()
        dap.listeners.before.attach.dapui_config = function()
          dapui.open()
        end
        dap.listeners.before.launch.dapui_config = function()
          dapui.open()
        end
        dap.listeners.before.event_terminated.dapui_config = function()
          dapui.close()
        end
        dap.listeners.before.event_exited.dapui_config = function()
          dapui.close()
        end
      end

      if ok_dap_python then
        dap_python.setup("uv", {
          console = "integratedTerminal",
        })

        local orig_python_adapter = dap.adapters.python

        local function is_uv_command(cmd)
          if not cmd then
            return false
          end
          if cmd == "uv" then
            return true
          end
          local tail = cmd:match("([^/\\]+)$")
          return tail == "uv"
        end

        dap.adapters.python = function(callback, config)
          orig_python_adapter(function(adapter)
            if adapter.type == "executable" and is_uv_command(adapter.command) then
              adapter.args = { "run", "--module", "debugpy.adapter" }
            end
            callback(adapter)
          end, config)
        end

        dap.adapters.debugpy = dap.adapters.python
      end

      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle breakpoint" })
      vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Debug: Continue" })
      vim.keymap.set("n", "<leader>n", dap.step_over, { desc = "Debug: Step over" })
      vim.keymap.set("n", "<leader>i", dap.step_into, { desc = "Debug: Step into" })
      vim.keymap.set("n", "<leader>o", dap.step_out, { desc = "Debug: Step out" })
    end
  },
  {
    "rcarriga/nvim-dap-ui", dependencies = {"mfussenegger/nvim-dap", "nvim-neotest/nvim-nio"}
  }
}

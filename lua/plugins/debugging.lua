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

      local dapui = require("dapui")
      local dap_python = require("dap-python")

      dap_python.setup("debugpy-adapter")

      dap.set_log_level("INFO")

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

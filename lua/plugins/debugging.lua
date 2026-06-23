return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      "mfussenegger/nvim-dap-python",
      "leoluz/nvim-dap-go",
      "jay-babu/mason-nvim-dap.nvim",
      "williamboman/mason.nvim",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- Initialize Mason
      require("mason").setup()
      require("mason-nvim-dap").setup({
        automatic_installation = true,
        ensure_installed = { "python", "codelldb", "delve" },
      })

      require("nvim-dap-virtual-text").setup({ commented = true })
      dapui.setup()

      -- UI Auto-open/close
      local function open_ui() dapui.open() end
      local function close_ui() dapui.close() end
      dap.listeners.before.attach.dapui_config = open_ui
      dap.listeners.before.launch.dapui_config = open_ui
      dap.listeners.before.event_terminated.dapui_config = close_ui
      dap.listeners.before.event_exited.dapui_config = close_ui

      -------------------------------------------------------------------------
      -- Visuals (Signs & Highlights)
      -------------------------------------------------------------------------
      vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e06c75" })
      vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#61afef" })
      vim.api.nvim_set_hl(0, "DapStopped", { fg = "#98c379", bold = true })
      vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#2c313c" })

      vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpoint" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DapBreakpoint" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DapBreakpoint" })
      vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DapLogPoint" })
      vim.fn.sign_define("DapStopped", { text = "", texthl = "DapStopped", linehl = "DapStoppedLine" })

      -------------------------------------------------------------------------
      -- Code Actions Integration
      -------------------------------------------------------------------------
      -- This adds a "Debug: Set Conditional Breakpoint" entry to your code actions
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          vim.api.nvim_buf_create_user_command(bufnr, "DapConditionalBreakpoint", function()
            dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
          end, {})
        end,
      })

      -------------------------------------------------------------------------
      -- Python Setup (Lazy & Defensive)
      -------------------------------------------------------------------------
      local function setup_python_dap()
        local ok_py, dap_python = pcall(require, "dap-python")
        if not ok_py then return end

        local function get_python_path()
          local ok_reg, registry = pcall(require, "mason-registry")
          if ok_reg then
            local ok_pkg, pkg = pcall(registry.get_package, "debugpy")
            if ok_pkg and type(pkg) == "table" and pkg.is_installed and pkg:is_installed() then
              local ok_path, path = pcall(function()
                if pkg.get_install_path then
                  return pkg:get_install_path() .. "/venv/bin/python"
                end
              end)
              if ok_path and path and vim.fn.executable(path) == 1 then
                return path
              end
            end
          end
          local fallback = vim.fn.exepath("python3")
          if fallback == "" then fallback = vim.fn.exepath("python") end
          return fallback ~= "" and fallback or "python"
        end

        dap_python.setup(get_python_path())

        if vim.fn.executable("uv") == 1 then
          dap.adapters.python = {
            type = "executable",
            command = "uv",
            args = { "run", "python", "-m", "debugpy.adapter" },
          }
        end
      end

      if vim.bo.filetype == "python" then
        setup_python_dap()
      else
        vim.api.nvim_create_autocmd("FileType", {
          pattern = "python",
          once = true,
          callback = setup_python_dap,
        })
      end

      -------------------------------------------------------------------------
      -- Go Setup
      -------------------------------------------------------------------------
      local function setup_go_dap()
        local ok_go, dap_go = pcall(require, "dap-go")
        if not ok_go then return end
        dap_go.setup()
      end

      if vim.bo.filetype == "go" then
        setup_go_dap()
      else
        vim.api.nvim_create_autocmd("FileType", {
          pattern = "go",
          once = true,
          callback = setup_go_dap,
        })
      end

      -------------------------------------------------------------------------
      -- C/C++/Rust (codelldb)
      -------------------------------------------------------------------------
      local function setup_codelldb()
        local ok_reg, registry = pcall(require, "mason-registry")
        if not ok_reg then return end

        local ok_pkg, pkg = pcall(registry.get_package, "codelldb")
        if ok_pkg and type(pkg) == "table" and pkg.is_installed and pkg:is_installed() then
          local ok_path, path = pcall(function() return pkg:get_install_path() end)
          if ok_path and path then
            local cmd = path .. "/extension/adapter/codelldb"
            dap.adapters.codelldb = {
              type = "server",
              port = "${port}",
              executable = { command = cmd, args = { "--port", "${port}" } },
            }
            dap.configurations.cpp = {
              {
                name = "Launch file",
                type = "codelldb",
                request = "launch",
                program = function() return vim.fn.input("Path: ", vim.fn.getcwd() .. "/", "file") end,
                cwd = "${workspaceFolder}",
                stopOnEntry = false,
              },
            }
            dap.configurations.c = dap.configurations.cpp
            dap.configurations.rust = dap.configurations.cpp
          end
        end
      end
      setup_codelldb()

      -- Keymaps
      local opts = { noremap = true, silent = true }
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, vim.tbl_extend("force", opts, { desc = "Debug: Toggle Breakpoint" }))
      vim.keymap.set("n", "<leader>dc", dap.continue, vim.tbl_extend("force", opts, { desc = "Debug: Continue" }))
      vim.keymap.set("n", "<leader>dt", dap.terminate, vim.tbl_extend("force", opts, { desc = "Debug: Terminate" }))
      vim.keymap.set("n", "<leader>du", dapui.toggle, vim.tbl_extend("force", opts, { desc = "Debug: Toggle UI" }))
      vim.keymap.set("n", "<leader>dh", function() require("dap.ui.widgets").hover() end, vim.tbl_extend("force", opts, { desc = "Debug: Hover" }))
    end,
  },
}

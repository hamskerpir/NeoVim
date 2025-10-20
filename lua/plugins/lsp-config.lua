return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "pyright" },
        automatic_installation = true,
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        terraformls = {},
        hcl = {},
        tflint = {},
      },
    },
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if ok_cmp then
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end

      -- Custom function for basedpyright logic
      -- 1. Define a generic on_attach function to set keymaps
      local on_attach = function(_, bufnr)
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc and ("LSP: " .. desc) or nil })
        end

        map("n", "K", vim.lsp.buf.hover, "Hover documentation")
        map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
        map("n", "gd", vim.lsp.buf.definition, "Go to definition")
        map("n", "gr", vim.lsp.buf.references, "Find references")
        map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
      end

      -- 2. Define or extend server configurations using vim.lsp.config()
      -- This replaces the loop and lspconfig[server].setup(config) calls.
      -- a. lua_ls
      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      })

      vim.lsp.config("pyright", {
        on_attach = on_attach,
        root_dir = vim.fs.root(
            vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p'),
            { 'pyproject.toml' }
        ),
      })

      vim.lsp.config('hcl', {
        on_attach = on_attach,
        root_dir = vim.fs.root(
           vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p'),
           { '.terraform', '.git' }
        ),
      })
      vim.lsp.config('terraformls', {
        on_attach = on_attach,
        filetypes = { "terraform", "terraform-vars" },
        root_dir = vim.fs.root(
           vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p'),
           { '.terraform', '.git' }
        ),
      })

      vim.lsp.enable({ "lua_ls", "ty", "terraformls", "hcl" })
    end,
  },
}

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
    config = function()
      -- NOTE: nvim-lspconfig is now used primarily for its server configuration definitions.
      -- The core setup logic now uses the native vim.lsp.config() and LspAttach.

      -- General LSP configuration settings
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

      -- Helper to create a custom root_dir function that uses vim.fs.find
      -- and mimics lspconfig.util.root_pattern
      local function create_root_dir_finder(patterns)
        return function(fname)
          -- vim.fs.find returns a list of paths, or nil if none found.
          local root_path = vim.fs.find(patterns, { upward = true, stop = vim.env.HOME })[1]
          return root_path and vim.fs.dirname(root_path) or nil
        end
      end

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
        -- Note: The root_dir is not explicitly set here, relying on lua_ls defaults
        -- or what nvim-lspconfig provides for lua_ls.
      })

      vim.lsp.config("ty", {})

      -- 3. Enable the configurations
      -- This tells Neovim to start these LSPs for their configured filetypes.
      -- (The filetypes are usually defined by nvim-lspconfig defaults and merged in).
      vim.lsp.enable({ "lua_ls", "ty" })
    end,
  },
}

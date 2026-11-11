return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    opts = {
      ensure_installed = {
        "lua",
        "javascript",
        "typescript",
        "tsx",
        "python",
        "cpp",
        "terraform",
        "hcl",
        "vue",
        "html",
        "css",
        "scss",
        "log",
      },
    },
    config = function(_, opts)
      local function register_custom_parsers()
        local parser_config = require("nvim-treesitter.parsers")
        parser_config.log = {
          install_info = {
            url = "https://github.com/Tudyx/tree-sitter-log",
            files = { "src/parser.c" },
            branch = "main",
          },
        }
      end

      -- Re-register custom parsers whenever nvim-treesitter reloads its parser table
      vim.api.nvim_create_autocmd("User", {
        pattern = "TSUpdate",
        callback = register_custom_parsers,
      })
      register_custom_parsers()

      -- new nvim-treesitter (main branch) is a parser manager only; no module opts
      require("nvim-treesitter").setup()

      if opts and opts.ensure_installed then
        require("nvim-treesitter").install(opts.ensure_installed)
      end

      vim.filetype.add({
        extension = { hcl = "hcl", tf = "terraform", log = "log" },
      })

      -- tsx grammar covers both TypeScript + JSX nodes; without this Neovim
      -- may use the typescript grammar which has no JSX rules
      vim.treesitter.language.register("tsx", "typescriptreact")
      vim.treesitter.language.register("tsx", "javascriptreact")

      -- new nvim-treesitter no longer sets up FileType autocmds; start manually
      -- pcall silently skips filetypes whose parser isn't installed
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "*",
        callback = function() pcall(vim.treesitter.start) end,
      })
    end,
  },
}

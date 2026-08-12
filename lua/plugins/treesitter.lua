return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      -- register the custom log parser before setup
      local parser_config = require("nvim-treesitter.parsers")
      parser_config.log = {
        install_info = {
          url = "https://github.com/Tudyx/tree-sitter-log",
          files = { "src/parser.c" },
          branch = "main",
        },
      }

      -- new nvim-treesitter (main branch) is a parser manager only; no module opts
      require("nvim-treesitter").setup()

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

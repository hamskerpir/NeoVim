return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "lua", "javascript", "python", "cpp", "terraform", "hcl", "vue" },
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)

      local parser_configs = require("nvim-treesitter.parsers").get_parser_configs()

      parser_configs.hcl = {
        filetype = {"hcl", "terraform"}
      }
    end,
  },
}

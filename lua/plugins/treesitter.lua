return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false, -- Treesitter should ideally not be lazy-loaded
    opts = {
      ensure_installed = { "lua", "javascript", "python", "cpp", "terraform", "hcl", "vue" },
      highlight = { enable = true },
      sync_install = false,
      auto_install = true,
      indent = { enable = true },
    },
    config = function(_, opts)
      local parser_config = require("nvim-treesitter.parsers")
      parser_config.log = {
        install_info = {
          url = "https://github.com/Tudyx/tree-sitter-log",
          files = { "src/parser.c" },
          branch = "main",
        },
      }

      table.insert(opts.ensure_installed, "log")
      require("nvim-treesitter").setup(opts)

    -- 2. DO NOT overwrite parser_configs. Use native filetype mapping instead.
    -- This maps both .hcl and .tf files correctly without breaking runtime queries.
    vim.filetype.add({
      extension = {
        hcl = "hcl",
        tf = "terraform",
        log = "log",
      },
    })
    end,
  },
}

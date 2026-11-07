return {
    "LunarVim/breadcrumbs.nvim",
    dependencies = {
        "SmiteshP/nvim-navic",
    },
    config = function()
      require("nvim-navic").setup {
          lsp = {
              auto_attach = true,
              preference = { "vue_ls", "vtsls" },
          },
      }

      require("breadcrumbs").setup()
    end
}


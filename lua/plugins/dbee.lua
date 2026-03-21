return {
  "kndndrj/nvim-dbee",
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
  build = function()
    -- Install/update core binaries
    require("dbee").install()
  end,
  config = function()
    require("dbee").setup({})
  end,
}

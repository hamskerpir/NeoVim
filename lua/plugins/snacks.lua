return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
        input = { enabled = true },  -- nicer floating input, used by opencode.nvim's ask()
        picker = { enabled = true }, -- fuzzy picker, used by opencode.nvim's select()
    },
}

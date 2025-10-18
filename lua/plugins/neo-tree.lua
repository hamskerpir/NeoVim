return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
  },
  config = function()
    local ok, neotree = pcall(require, "neo-tree")
    if ok then
      neotree.setup({
        close_if_last_window = true,
        window = {
          mappings = {
            ["<C-f>"] = {
              function ()
                if _G.SwitcherHydra then
                  _G.SwitcherHydra:activate()
                end
              end,
            },
            ["n"] = "add",
            ["<cr>"] = "open",
            ["S"] = "open_split",
            ["s"] = "open_vsplit",
            ["t"] = "open_tabnew",
            ["w"] = "open_with_window_picker",
          },
        },
        filesystem = {
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_ignored = false,
            hide_by_name = {
              ".venv",
            },
            hide_by_pattern = {
              "*.pyc",
            },
            never_show = {
              ".DS-Store",
            }
          },
          window = {
            mappings = {
              ["/"] = "fuzzy_finder",
              ["f"] = "filter_on_submit",
            },
          },
          follow_current_file = {
            enabled = true,
          },
        },
        buffers = {
          window = {
            mappings = {},
          },
        },
        git_status = {
          window = {
            mappings = {},
          },
        },
      })
    end
  end,
}

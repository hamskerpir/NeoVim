return {
  "LintaoAmons/scratch.nvim",
  event = "VeryLazy",
  config = function ()
    local scratch = require('scratch')
    scratch.setup({
      scratch_file_dir = "~/.scratch"
    })
  end
}


return {
	"nvimtools/hydra.nvim",
	config = function()
		local Hydra = require("hydra")
		local cmd = require("hydra.keymap-util").cmd

		local switcher = Hydra({
			name = "Switcher", -- Optional name for the hint
			mode = "n", -- Normal mode ('n') or other modes ('v', 'i', etc.)
			body = "<C-f>", -- The key sequence to summon the Hydra
			heads = {
				-- { 'key', 'command', { options } }
				{ "1", "<Cmd>Neotree<Cr>", { desc = "File manager (Neotree)", nowait = true } },
				{ "2", "<Cmd>BookmarkShowAll<Cr>", { desc = "Bookmarks", nowait = true } },

				{ "8", cmd("DiffviewFileHistory"), { desc = "Show commit history", nowait = true } },
				{
					"9",
					function()
						local filename = vim.fn.expand("%")
						vim.api.nvim_command("DiffviewFileHistory " .. filename)
					end,
					{ desc = "Show commit history for file" },
				},
				{ "0", cmd("LazyGit"), { desc = "LazyGit", nowait = true } },
				{ "d", function() require("dbee").toggle() end, { desc = "Dbee (Database UI)", nowait = true } },
				--
				{ "b", "<Cmd>BookmarkAnnotate<Cr>", { desc = "Annotate new Bookmark", nowait = true } },
				{ "f", cmd("Telescope live_grep") },
				{ "e", cmd("Telescope oldfiles"), { desc = "Recent files", nowait = true } },
				{ "o", cmd("Telescope find_files"), { desc = "Find files", nowait = true } },
				{ "p", cmd("Telescope project"), { desc = "Open projects", nowait = true } },
				{ "7", cmd("AerialToggle"), { desc = "Open file structure", nowait = true } },
				{ "S", cmd("AerialNavToggle"), { desc = "Open file structure modal", nowait = true } },
				{ "n", cmd("tabnew | ScratchWithName"), { desc = "New scratch file", nowait = true } },
				{ "h", cmd("HttpView"), { desc = "HTTP View window", nowait = true } },
				{ "N", cmd("ScratchOpenFzf"), { desc = "Search scratch", nowait = true } },
				{ "E", vim.diagnostic.setqflist, { desc = "Issues", nowait = true } },
			},
			config = {
				invoke_on_body = true,
				color = "blue", -- 'blue' (exit after head) or 'red' (continue after head)
				hint = {
					position = "middle",
				},
			},
			hint = [[

     _1_ File Manager               _e_ Recent Files (Telescope)
     _2_ Bookmarks Show All         _b_ Annotate New Bookmark
                                  _o_ Search files
     _7_ File structure             _S_ File Structure Modal
     _8_ Commit history             _f_ Find in Files
     _9_ Commits for file           _p_ Open project
     _0_ LazyGit
     _d_ Dbee (Database UI)         _n_ New scratch
     _h_ Http View                  _N_ Search scratch
                                  _E_ Issues

    ]],
			opts = {},
		})

		_G.SwitcherHydra = switcher
	end,
}

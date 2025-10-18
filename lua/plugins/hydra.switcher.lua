return { "nvimtools/hydra.nvim", config = function()
  local Hydra = require('hydra')
  local cmd = require('hydra.keymap-util').cmd
  local gitsigns = require('gitsigns')

  local gitHydra = Hydra({
     name = 'Git',
     hint = [[
 _J_: next hunk   _s_: stage hunk        _d_: show deleted   _b_: blame line
 _K_: prev hunk   _u_: undo last stage   _p_: preview hunk   _B_: blame show full 
 ^ ^              _S_: stage buffer      ^ ^                 _/_: show base file
 ^
 ^ ^              _<Enter>_: Neogit              _q_: exit
]],
     config = {
        color = 'pink',
        invoke_on_body = true,
        on_enter = function()
           vim.cmd 'mkview'
           vim.cmd 'silent! %foldopen!'
           vim.bo.modifiable = false
           gitsigns.toggle_signs(true)
           gitsigns.toggle_linehl(true)
        end,
        on_exit = function()
           local cursor_pos = vim.api.nvim_win_get_cursor(0)
           vim.cmd 'loadview'
           vim.api.nvim_win_set_cursor(0, cursor_pos)
           vim.cmd 'normal zv'
           gitsigns.toggle_signs(false)
           gitsigns.toggle_linehl(false)
           gitsigns.toggle_deleted(false)
        end,
     },
     mode = {'n','x'},
     heads = {
        { 'J',
           function()
              if vim.wo.diff then return ']c' end
              vim.schedule(function() gitsigns.next_hunk() end)
              return '<Ignore>'
           end,
           { expr = true, desc = 'next hunk' } },
        { 'K',
           function()
              if vim.wo.diff then return '[c' end
              vim.schedule(function() gitsigns.prev_hunk() end)
              return '<Ignore>'
           end,
           { expr = true, desc = 'prev hunk' } },
        { 's', ':Gitsigns stage_hunk<CR>', { silent = true, desc = 'stage hunk' } },
        { 'u', gitsigns.undo_stage_hunk, { desc = 'undo last stage' } },
        { 'S', gitsigns.stage_buffer, { desc = 'stage buffer' } },
        { 'p', gitsigns.preview_hunk, { desc = 'preview hunk' } },
        { 'd', gitsigns.toggle_deleted, { nowait = true, desc = 'toggle deleted' } },
        { 'b', gitsigns.blame_line, { desc = 'blame' } },
        { 'B', function() gitsigns.blame_line{ full = true } end, { desc = 'blame show full' } },
        { '/', gitsigns.show, { exit = true, desc = 'show base file' } }, -- show the base of the file
        { '<Enter>', '<Cmd>Neogit<CR>', { exit = true, desc = 'Neogit' } },
        { 'q', nil, { exit = true, nowait = true, desc = 'exit' } },
     }
  })

  local optionsHydra = Hydra({
   name = 'Options',
   hint = [[
  ^ ^        Options
  ^
  _v_ %{ve} virtual edit
  _i_ %{list} invisible characters  
  _s_ %{spell} spell
  _w_ %{wrap} wrap
  _c_ %{cul} cursor line
  _n_ %{nu} number
  _r_ %{rnu} relative number
  ^
       ^^^^                _<Esc>_
]],
   config = {
      color = 'amaranth',
      invoke_on_body = true,
      hint = {
         position = 'middle'
      }
   },
   mode = {'n','x'},
   body = '<leader>o',
   heads = {
      { 'n', function()
         if vim.o.number == true then
            vim.o.number = false
         else
            vim.o.number = true
         end
      end, { desc = 'number' } },
      { 'r', function()
         if vim.o.relativenumber == true then
            vim.o.relativenumber = false
         else
            vim.o.number = true
            vim.o.relativenumber = true
         end
      end, { desc = 'relativenumber' } },
      { 'v', function()
         if vim.o.virtualedit == 'all' then
            vim.o.virtualedit = 'block'
         else
            vim.o.virtualedit = 'all'
         end
      end, { desc = 'virtualedit' } },
      { 'i', function()
         if vim.o.list == true then
            vim.o.list = false
         else
            vim.o.list = true
         end
      end, { desc = 'show invisible' } },
      { 's', function()
         if vim.o.spell == true then
            vim.o.spell = false
         else
            vim.o.spell = true
         end
      end, { exit = true, desc = 'spell' } },
      { 'w', function()
         if vim.o.wrap ~= true then
            vim.o.wrap = true
            -- Dealing with word wrap:
            -- If cursor is inside very long line in the file than wraps
            -- around several rows on the screen, then 'j' key moves you to
            -- the next line in the file, but not to the next row on the
            -- screen under your previous position as in other editors. These
            -- bindings fixes this.
            vim.keymap.set('n', 'k', function() return vim.v.count > 0 and 'k' or 'gk' end,
                                     { expr = true, desc = 'k or gk' })
            vim.keymap.set('n', 'j', function() return vim.v.count > 0 and 'j' or 'gj' end,
                                     { expr = true, desc = 'j or gj' })
         else
            vim.o.wrap = false
            vim.keymap.del('n', 'k')
            vim.keymap.del('n', 'j')
         end
      end, { desc = 'wrap' } },
      { 'c', function()
         if vim.o.cursorline == true then
            vim.o.cursorline = false
         else
            vim.o.cursorline = true
         end
      end, { desc = 'cursor line' } },
      { '<Esc>', nil, { exit = true } }
   }
  })

  local switcher = Hydra({
    name = "Switcher",  -- Optional name for the hint
    mode = 'n',             -- Normal mode ('n') or other modes ('v', 'i', etc.)
    body = '<C-f>',         -- The key sequence to summon the Hydra
    heads = {
        -- { 'key', 'command', { options } }
        { '1', '<Cmd>Neotree<Cr>', { desc = 'File manager (Neotree)', nowait = true } },
        { '2', '<Cmd>BookmarkShowAll<Cr>', { desc = 'Bookmarks', nowait = true } },

        { '0', cmd 'LazyGit', { desc = 'LazyGit', nowait = true } },
        --
        { 'b', '<Cmd>BookmarkAnnotate<Cr>', { desc = 'Annotate new Bookmark', nowait = true } },
        { 'f', cmd 'Telescope live_grep' },
        { 'e', cmd 'Telescope oldfiles', { desc = 'Recent files', nowait = true } },
        { 'o', cmd 'Telescope find_files', { desc = 'Find files', nowait = true } },
        { 'p', cmd 'Telescope project', { desc = 'Open projects', nowait = true } },
        { 'g', function() gitHydra:activate() end, { desc = 'Open projects', nowait = true } },
        --
        { ',', function() optionsHydra:activate() end, { desc = 'Open projects', nowait = true } },
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
     _0_ Git                        _f_ Find in Files 
                                  _p_ Open project 
                                  _g_ Git menu 
    _,_ Editor Options

    ]],
    opts = {

    }
  })

  _G.SwitcherHydra = switcher

  end
}


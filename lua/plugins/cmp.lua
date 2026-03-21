return {
  'git@github.com:hrsh7th/nvim-cmp.git',
  dependencies = {

  -- Required: LSP Source
    'git@github.com:hrsh7th/cmp-nvim-lsp.git',
    -- Required: Snippet Engine
    'git@github.com:L3MON4D3/LuaSnip.git',
    'git@github.com:saadparwaiz1/cmp_luasnip.git',
    'git@github.com:hrsh7th/cmp-buffer.git',
    'git@github.com:hrsh7th/cmp-path.git',
    'git@github.com:onsails/lspkind-nvim.git',
    'git@github.com:hrsh7th/cmp-nvim-lsp-signature-help.git',
  },
  config = function()
    local cmp = require('cmp')
    local luasnip = require('luasnip')
    local lspkind = require('lspkind')

    cmp.setup({
      sources = cmp.config.sources({
        { name = 'nvim_lsp', priority = 10 },
        { name = 'nvim_lsp_signature_help', priority = 9 },
        { name = 'luasnip', priority = 8 },
        { name = 'buffer', priority = 5, keyword_length = 3 }, -- Only suggest words > 3 chars
        { name = 'path', priority = 4 },
      }),
      formatting = {
        format = lspkind.cmp_format({
          with_text = true, -- Show text alongside icon
          maxwidth = 50,    -- Max width of the item
          menu = {          -- Custom labels for sources
            nvim_lsp = "[LSP]",
            luasnip = "[Snip]",
            buffer = "[Text]",
            path = "[Path]",
          },
        }),
      },

      -- 2. Define Key Mappings
      mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),

        -- Improved Tab/S-Tab logic (no changes here, but good to keep)
        ['<Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { 'i', 's' }),

        ['<S-Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { 'i', 's' }),
      }),

      -- 3. Customization
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
      performance = {
        debounce = 100,
      },
      experimental = {
        ghost_text = true,
      }
    })

    -- ✨ NEW: Configuration to enable auto-source for filetypes (e.g., in commit messages)
    -- This makes buffer suggestions work in git commits and text files.
    cmp.setup.filetype({ 'gitcommit', 'markdown', 'text' }, {
        sources = cmp.config.sources({
            { name = 'buffer' },
        }),
    })
  end,
}

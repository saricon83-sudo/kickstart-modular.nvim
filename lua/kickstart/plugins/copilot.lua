-- ~/.config/nvim/lua/custom/plugins/copilot.lua
return {
  -- Copilot core
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    build = ':Copilot auth',
    opts = {
      suggestion = { enabled = true }, -- disable inline ghost text
      panel = { enabled = true },
    },
  },

  -- Copilot completion source for nvim-cmp
  {
    'zbirenbaum/copilot-cmp',
    dependencies = { 'zbirenbaum/copilot.lua' },
    config = function()
      require('copilot_cmp').setup()
    end,
  },

  -- Hook Copilot into cmp sources
  {
    'hrsh7th/nvim-cmp',
    opts = function(_, opts)
      local cmp = require 'cmp'

      opts.preselect = cmp.PreselectMode.Item
      opts.completion = { completeopt = 'menu,menuone,noinsert' }

      opts.mapping = cmp.mapping.preset.insert {
        ['<C-n>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
        ['<C-p>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },
        ['<CR>'] = cmp.mapping.confirm { select = true }, -- Enter accepts
        ['<Tab>'] = cmp.mapping.confirm { select = true }, -- Tab also accepts
      }

      opts.sources = opts.sources or {}
      table.insert(opts.sources, 1, { name = 'copilot' })

      return opts
    end,
  },
}

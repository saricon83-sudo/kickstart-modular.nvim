return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
      ensure_installed = { 'bash', 'c', 'diff', 'html', 'go', 'c_sharp', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
      textobjects = {
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            ['<leader>nf'] = '@function.outer',
          },
          goto_previous_start = {
            ['<leader>pf'] = '@function.outer',
          },
          goto_next_end = {
            [']f'] = '@function.outer',
          },
          goto_previous_end = {
            ['[f'] = '@function.outer',
          },
        },
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ['af'] = '@function.outer',
            ['if'] = '@function.inner',
          },
        },
      },
    },
    config = function(_, opts)
      require('nvim-treesitter.configs').setup(opts)

      -- Custom keybinding to jump to function name
      vim.keymap.set('n', '<leader>jf', function()
        -- Clear search highlighting
        vim.cmd('nohlsearch')
        
        local ts_utils = require 'nvim-treesitter.ts_utils'
        local node = ts_utils.get_node_at_cursor()

        -- Traverse up to find the function node
        while node do
          local node_type = node:type()
          if node_type:match 'function' or node_type:match 'method' or node_type == 'function_declaration' or node_type == 'function_definition' then
            -- Try to get the name node
            local name_node = node:field('name')[1]
            if name_node then
              -- Get the start position of the name node
              local start_row, start_col = name_node:start()
              vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
              return
            end
            -- Fallback: go to start of function
            local start_row, start_col = node:start()
            vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
            return
          end
          node = node:parent()
        end
        vim.notify('Not inside a function', vim.log.levels.WARN)
      end, { desc = 'Jump to function name' })
    end,
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  },
}
-- vim: ts=2 sts=2 sw=2 et

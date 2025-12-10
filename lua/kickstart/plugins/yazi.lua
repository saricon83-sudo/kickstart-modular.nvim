---@type LazySpec
return {
  'mikavilpas/yazi.nvim',
  version = '*',
  event = 'VeryLazy',
  dependencies = {
    { 'nvim-lua/plenary.nvim', lazy = true },
  },
  keys = {
    {
      '<leader>y',
      mode = { 'n', 'v' },
      '<cmd>Yazi<cr>',
      desc = 'Open yazi at the current file',
    },
    {
      '<leader>cw',
      '<cmd>Yazi cwd<cr>',
      desc = "Open yazi in nvim's cwd",
    },
  },
  ---@type YaziConfig | {}
  opts = {
    -- valfritt, men nice om du vill jobba “projekt-root-first”
    open_for_directories = false,
    change_neovim_cwd_on_close = true,
  },
}

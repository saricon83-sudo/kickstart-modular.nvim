return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "hrsh7th/nvim-cmp", -- Optional: For autocompletion inside the chat
    "nvim-telescope/telescope.nvim", -- Optional: For searching
    { "stevearc/dressing.nvim", opts = {} }, -- Optional: Improve UI look
  },
  config = function()
    -- Determine default adapter based on environment variables or available integrations
    local default_adapter = "ollama"
    if vim.env.GEMINI_API_KEY then
      default_adapter = "gemini"
    elseif vim.env.ANTHROPIC_API_KEY then
      default_adapter = "anthropic"
    elseif vim.env.OPENAI_API_KEY then
      default_adapter = "openai"
    end

    require("codecompanion").setup({
      strategies = {
        chat = {
          adapter = default_adapter,
        },
        inline = {
          adapter = default_adapter,
        },
        agent = {
          adapter = default_adapter,
        },
      },
      interactions = {
        cli = {
          agent = "copilot", -- Default CLI agent (e.g. copilot, claude_code, etc.)
        },
      },
      adapters = {
        ollama = function()
          return require("codecompanion.adapters").extend("ollama", {
            schema = {
              model = {
                default = "qwen2.5-coder:7b",
              },
            },
          })
        end,
        gemini = function()
          return require("codecompanion.adapters").extend("gemini", {
            schema = {
              model = {
                default = "gemini-2.5-flash",
              },
            },
          })
        end,
        anthropic = function()
          return require("codecompanion.adapters").extend("anthropic", {
            schema = {
              model = {
                default = "claude-3-5-sonnet-latest",
              },
            },
          })
        end,
        openai = function()
          return require("codecompanion.adapters").extend("openai", {
            schema = {
              model = {
                default = "gpt-4o",
              },
            },
          })
        end,
      },
      opts = {
        -- Set log level to trace errors if needed
        log_level = "ERROR",
      },
    })

    -- ── Chat ─────────────────────────────────────────────────────────────────
    vim.keymap.set({ 'n', 'v' }, '<leader>ia', '<cmd>CodeCompanionActions<cr>', { desc = 'AI: Actions menu' })
    vim.keymap.set({ 'n', 'v' }, '<leader>ic', '<cmd>CodeCompanionChat Toggle<cr>', { desc = 'AI: Toggle chat' })
    vim.keymap.set('v', '<leader>is', '<cmd>CodeCompanionChat Add<cr>', { desc = 'AI: Send selection to chat' })

    -- ── Inline (the fast path) ────────────────────────────────────────────────
    -- Prompt then apply inline to current line/selection
    vim.keymap.set({ 'n', 'v' }, '<leader>ii', function()
      vim.ui.input({ prompt = '󰚩  ' }, function(input)
        if input and input ~= '' then
          vim.cmd('CodeCompanion ' .. input)
        end
      end)
    end, { desc = 'AI: Inline prompt' })

    -- Direct "fix" with no prompt — most common single action
    vim.keymap.set({ 'n', 'v' }, '<leader>if', '<cmd>CodeCompanion fix this<cr>', { desc = 'AI: Fix' })

    -- Inline prompt scoped to the entire current function (treesitter-aware)
    -- Grabs the prompt first, then selects `af` so the visual mark is fresh
    vim.keymap.set('n', '<leader>iF', function()
      vim.ui.input({ prompt = '󰚩 on function: ' }, function(input)
        if input and input ~= '' then
          vim.cmd 'normal! vaf'
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes(':<C-u>CodeCompanion ' .. input .. '<CR>', true, false, true),
            'n',
            true
          )
        end
      end)
    end, { desc = 'AI: Inline on current function' })

    -- ── CLI Interactions ──────────────────────────────────────────────────────
    vim.keymap.set({ 'n', 'v' }, '<LocalLeader>cp', function()
      return require('codecompanion').cli({ prompt = true })
    end, { desc = 'AI CLI: Prompt agent' })

    vim.keymap.set({ 'n', 'v' }, '<LocalLeader>ca', function()
      return require('codecompanion').cli('#{this}', { focus = false })
    end, { desc = 'AI CLI: Add context' })

    vim.keymap.set('n', '<LocalLeader>cd', function()
      return require('codecompanion').cli('#{diagnostics} Can you fix these?', { focus = false, submit = true })
    end, { desc = 'AI CLI: Fix diagnostics' })

    vim.keymap.set('n', '<LocalLeader>ct', function()
      return require('codecompanion').cli('#{terminal} Sharing the output from the terminal. Can you fix it?', { focus = false, submit = true })
    end, { desc = 'AI CLI: Fix terminal output' })

    -- =========================================================================
    -- CODECOMPANION KEYBINDINGS GUIDE
    -- =========================================================================
    --
    -- Inline (fast path — no menu required):
    --   <Leader>ii  - Prompt then edit inline at cursor / selection  ← main shortcut
    --   <Leader>if  - Fix current line/selection inline (no prompt)
    --   <Leader>iF  - Prompt then edit the entire current function inline
    --
    -- Chat:
    --   <Leader>ia  - Open AI Actions menu
    --   <Leader>ic  - Toggle chat window
    --   <Leader>is  - Add visual selection to chat (Visual mode)
    --
    -- CLI (using <LocalLeader>, defaults to \):
    --   <LocalLeader>cp  - Prompt CLI agent
    --   <LocalLeader>ca  - Add context/selection to CLI agent
    --   <LocalLeader>cd  - Send diagnostics to CLI agent
    --   <LocalLeader>ct  - Send terminal output to CLI agent
    --
    -- =========================================================================

    -- Inline Spinner: shows an animated braille spinner as virtual text while
    -- the LLM is processing an inline request.
    local inline_spinners = {}
    local ns_id = vim.api.nvim_create_namespace('CodeCompanionInlineSpinner')
    local spinner_symbols = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
    local spinner_symbols_len = #spinner_symbols

    local function clean_spinner(bufnr)
      local spinner_state = inline_spinners[bufnr]
      if spinner_state then
        if spinner_state.timer then
          spinner_state.timer:stop()
          spinner_state.timer:close()
        end
        if vim.api.nvim_buf_is_valid(bufnr) and spinner_state.extmark_id then
          pcall(vim.api.nvim_buf_del_extmark, bufnr, ns_id, spinner_state.extmark_id)
        end
        inline_spinners[bufnr] = nil
      end
    end

    local inline_group = vim.api.nvim_create_augroup('CodeCompanionInlineSpinnerGroup', { clear = true })

    vim.api.nvim_create_autocmd({ 'User' }, {
      pattern = 'CodeCompanionRequest*',
      group = inline_group,
      callback = function(request)
        local data = request.data
        if not data or data.interaction ~= 'inline' or not data.bufnr or not data.buffer_context then
          return
        end

        local bufnr = data.bufnr
        if request.match == 'CodeCompanionRequestStarted' then
          clean_spinner(bufnr)

          local start_line = data.buffer_context.start_line
          local spinner_state = { spinner_index = 1, extmark_id = nil }

          local uv = vim.uv or vim.loop
          spinner_state.timer = uv.new_timer()
          spinner_state.timer:start(0, 80, vim.schedule_wrap(function()
            if not vim.api.nvim_buf_is_valid(bufnr) then
              clean_spinner(bufnr)
              return
            end

            spinner_state.spinner_index = (spinner_state.spinner_index % spinner_symbols_len) + 1
            local symbol = spinner_symbols[spinner_state.spinner_index]

            local ok, ext_id = pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, start_line - 1, 0, {
              id = spinner_state.extmark_id,
              virt_text = {
                { '󰚩 ', 'DiagnosticWarn' },
                { symbol .. ' ', 'DiagnosticWarn' },
                { 'LLM is thinking...', 'Comment' },
              },
              virt_text_pos = 'eol',
            })
            if ok then
              spinner_state.extmark_id = ext_id
            end
          end))

          inline_spinners[bufnr] = spinner_state

        elseif request.match == 'CodeCompanionRequestFinished' then
          clean_spinner(bufnr)
        end
      end,
    })

    vim.api.nvim_create_autocmd({ 'User' }, {
      pattern = 'CodeCompanionInlineFinished',
      group = inline_group,
      callback = function(request)
        local bufnr = request.buf or vim.api.nvim_get_current_buf()
        clean_spinner(bufnr)
      end,
    })
  end,
}

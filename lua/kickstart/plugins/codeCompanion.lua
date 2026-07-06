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

    -- Practical Keymaps using <leader>i to prevent conflicts with Harpoon (<leader>a)
    vim.keymap.set({ "n", "v" }, "<leader>ia", "<cmd>CodeCompanionActions<cr>", { desc = "AI Actions" })
    vim.keymap.set({ "n", "v" }, "<leader>ic", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "Toggle AI Chat" })
    vim.keymap.set("v", "<leader>is", "<cmd>CodeCompanion /buffer<cr>", { desc = "Send selection to AI" })

    -- CLI Interaction Keymaps
    vim.keymap.set({ "n", "v" }, "<LocalLeader>cp", function()
      return require("codecompanion").cli({ prompt = true })
    end, { desc = "Prompt the CLI agent" })

    vim.keymap.set({ "n", "v" }, "<LocalLeader>ca", function()
      return require("codecompanion").cli("#{this}", { focus = false })
    end, { desc = "Add context to the CLI agent" })

    vim.keymap.set("n", "<LocalLeader>cd", function()
      return require("codecompanion").cli("#{diagnostics} Can you fix these?", { focus = false, submit = true })
    end, { desc = "Send diagnostics to CLI agent" })

    vim.keymap.set("n", "<LocalLeader>ct", function()
      return require("codecompanion").cli("#{terminal} Sharing the output from the terminal. Can you fix it?", { focus = false, submit = true })
    end, { desc = "Send terminal output to CLI agent" })

    -- =========================================================================
    -- CODECOMPANION KEYBINDINGS GUIDE
    -- =========================================================================
    --
    -- Chat & Inline Actions (using <Leader>, defaults to Space):
    --   <Leader>ia  - Open AI Actions menu (Normal & Visual modes)
    --   <Leader>ic  - Toggle AI Chat window (Normal & Visual modes)
    --   <Leader>is  - Send visual selection to AI (Visual mode only)
    --
    -- CLI Interactions (using <LocalLeader>, defaults to \):
    --   <LocalLeader>cp  - Prompt CLI agent (opens prompt input)
    --   <LocalLeader>ca  - Add current context/selection to CLI agent in background
    --   <LocalLeader>cd  - Send LSP diagnostics of current buffer & ask to fix
    --   <LocalLeader>ct  - Send latest terminal output to CLI agent
    --
    -- =========================================================================
  end,
}

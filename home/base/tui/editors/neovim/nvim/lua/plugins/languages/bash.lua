return {

  -- lsp configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- @type lspconfig.options
      servers = {
        bashls = {},
      },
    },
  },

  config = {
    -- Whether a repl should be discarded or not
    scratch_repl = true,
    -- Your repl definitions come here
    repl_definition = {
      sh = {
        command = { "bash" },
      },
    },
    -- How the repl window will be displayed
    -- See below for more information
    repl_open_cmd = require("iron.view").bottom(40),
  },

  -- repl
  {
    "hkupty/iron.nvim",
    config = function()
      local iron = require("iron.core")
      iron.setup({
        config = {
          -- Whether a repl should be discarded or not
          scratch_repl = true,
          repl_open_cmd = "rightbelow 40vsplit | set nonu | set norelativenumber | set signcolumn=no ",
          repl_definition = {
            sh = {
              command = "bash",
            },
          },
        },
        keymaps = {
          visual_send = "<leader><space>",
          send_line = "<leader><space>",
          cr = "<space>s<cr>",
          interrupt = "<space>s<space>",
          exit = "<space>sq",
          clear = "<space>cl",
        },
        highlight = {
          italic = true,
        },
        ignore_blank_lines = false,
      })
    end,
  },
}

-- contains lsp configuration, dap configuration, and repl configuration

return {
  -- lsp configuration
  {
    "neovim/nvim-lspconfig",
  },
  -- cmdline tools and lsp servers
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    -- opts = {
    --   github = {
    --     -- The template URL to use when downloading assets from github.
    --     -- use kgithub as github mirror site.
    --     download_url_template = "https://kgithub.com/%s/releases/download/%s/%s",
    --   },
    -- },
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
  },

  {
    "rcarriga/nvim-dap-ui",
    opts = {
      mappings = {
        -- enable LeftMouse
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "o",
        remove = "d",
        edit = "e",
        repl = "r",
      },
    },
  },

  -- repl config
  {
    "hkupty/iron.nvim",
    ft = { "sh", "py", "r" },
  },

  {
    "folke/snacks.nvim",
  },

  { import = "plugins.languages" },
}

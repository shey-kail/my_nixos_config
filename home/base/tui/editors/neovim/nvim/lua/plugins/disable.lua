--disable some plugins that lazyvim has by default

return {
  -- disable tokyonight (theme)
  {
    "folke/tokyonight.nvim",
    enabled = false,
  },

  -- disable catppuccin (theme)
  {
    "catppuccin/nvim",
    enabled = false,
  },

  -- disable mini.ai (extend and create `a`/`i` textobjects)
  {
    "echasnovski/mini.ai",
    enabled = false,
  },

  -- disable mini.indentscope
  {
    "echasnovski/mini.indentscope",
    enabled = false,
  },
}

return {

  { "Mofiqul/vscode.nvim", opts = { transparent = true } },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "vscode",
    },
  },

  {
    "akinsho/bufferline.nvim",
    keys = {
      { "<A-1>", mode = { "n", "i" }, "<Cmd>BufferLineGoToBuffer 1<CR>", desc = "go to buffer 1" },
      { "<A-2>", mode = { "n", "i" }, "<Cmd>BufferLineGoToBuffer 2<CR>", desc = "go to buffer 2" },
      { "<A-3>", mode = { "n", "i" }, "<Cmd>BufferLineGoToBuffer 3<CR>", desc = "go to buffer 3" },
      { "<A-4>", mode = { "n", "i" }, "<Cmd>BufferLineGoToBuffer 4<CR>", desc = "go to buffer 4" },
      { "<A-5>", mode = { "n", "i" }, "<Cmd>BufferLineGoToBuffer 5<CR>", desc = "go to buffer 5" },
      { "<A-6>", mode = { "n", "i" }, "<Cmd>BufferLineGoToBuffer 6<CR>", desc = "go to buffer 6" },
      { "<A-,>", mode = { "n", "i" }, "<Cmd>BufferLineCyclePrev<CR>", desc = "go to previous buffer" },
      { "<A-.>", mode = { "n", "i" }, "<Cmd>BufferLineCycleNext<CR>", desc = "go to next buffer" },
      {
        "<A-<>",
        mode = { "n", "i" },
        "<Cmd>BufferLineMovePrev<CR>",
        desc = "move the current to previous position",
      },
      { "<A->>", mode = { "n", "i" }, "<Cmd>BufferLineMoveNext<CR>", desc = "move the current to next position" },
      { "<A-p>", mode = { "n", "i" }, "<Cmd>BufferLineTogglePin<CR>", desc = "pin the current buffer" },
      { "<leader>bp", false },
      { "<leader>bP", false },
      { "<leader>bo", false },
      { "<leader>br", false },
      { "<leader>bl", false },
      { "<S-h>", false },
      { "<S-l>", false },
      { "[b", false },
      { "]b", false },
    },
  },

  {
    "nvim-mini/mini.bufremove",

    keys = {
      {
        "<A-c>",
        function()
          local bd = require("mini.bufremove").delete
          if vim.bo.modified then
            local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
            if choice == 1 then -- Yes
              vim.cmd.write()
              bd(0)
            elseif choice == 2 then -- No
              bd(0, true)
            end
          else
            bd(0)
          end
        end,
        desc = "Delete Buffer",
      },
      {
        "<leader>bd",
        false,
      },
      {
        "<leader>bD",
        false,
      },
    },
  },
}

-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- the function map(mode, lhs, rhs, opts)
-- {mode}  Mode short-name (map command prefix: "n", "i", "v", "x", …) or "!" for |:map!|, or empty string for |:map|.
-- {lhs}   Left-hand-side |{lhs}| of the mapping.
-- {rhs}   Right-hand-side |{rhs}| of the mapping.
-- {opts}  Optional parameters map. Accepts all |:map-arguments| as keys excluding |<buffer>| but including |noremap| and "desc". "desc" can be used to give a description to keymap. When called from Lua, also accepts a "callback" key that takes a Lua function to call when the mapping is executed. Values are Booleans. Unknown key is an error.
local function noremap(mode, lhs, rhs, opts)
  local options = { noremap = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

-- the function map(mode, lhs, rhs, opts)
-- {mode}  Mode short-name (map command prefix: "n", "i", "v", "x", …) or "!" for |:map!|, or empty string for |:map|.
-- {lhs}   Left-hand-side |{lhs}| of the mapping.
-- {rhs}   Right-hand-side |{rhs}| of the mapping.
-- {opts}  Optional parameters map. Accepts all |:map-arguments| as keys excluding |<buffer>| but including |noremap| and "desc". "desc" can be used to give a description to keymap. When called from Lua, also accepts a "callback" key that takes a Lua function to call when the mapping is executed. Values are Booleans. Unknown key is an error.
local function map(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- ===
-- === Remap space as leader key
-- ===
vim.g.mapleader = " "
-- vim.g.maplocalleader = " "

-- ===
-- === windows management
-- ===
-- use <space> + hjkl for moving the cursor around windows
noremap("n", "<leader>w", "<C-w>w", {})
noremap("n", "<leader>h", "<C-w>h", {})
noremap("n", "<leader>j", "<C-w>j", {})
noremap("n", "<leader>k", "<C-w>k", {})
noremap("n", "<leader>l", "<C-w>l", {})
-- resize splits with arrow keys
noremap("n", "<up>", ":res +5<CR>", {})
noremap("n", "<down>", ":res -5<CR>", {})
noremap("n", "<left>", ":vertical resize-5<CR>", {})
noremap("n", "<right>", ":vertical resize+5<CR>", {})
-- vertical to horizontal ( | -> -- )
noremap("n", "<leader>z", "<C-w>t<C-w>K", {})
noremap("n", "<leader>v", "<C-w>t<C-w>H", {})
--use Ctrl+jk for repaid warching
noremap("n", "<C-j>", "5j", {})
noremap("n", "<C-k>", "5k", {})
--use alt+o to add a new line down
noremap("i", "<A-o>", "<Esc>o", {})
--use alt+O to add a new line up
noremap("i", "<A-O>", "<Esc>O", {})
--use <Esc> to exit terminal-mode
noremap("t", "<Esc>", "<C-\\><C-n>", {})

-- "Iron preview variable"
noremap("n", "<leader>pv", function()
  -- 判断文件类型
  -- 如果是R文件，则执行R的dataframe预览
  if vim.bo.filetype == "r" then
    require("iron.core").send(nil, "View(" .. vim.fn.expand("<cword>") .. ")")
  else
    -- 如果是其他的, 则执行预览变量
    require("iron.core").send(nil, vim.fn.expand("<cword>"))
  end
end, bufopts)

-- ===
-- === <space>m to transfrom mouse enable/disable
-- ===
noremap("n", "<space>m", function()
  if vim.o.mouse == "" then
    vim.o.mouse = "a"
    print("Mouse enabled")
  else
    vim.o.mouse = ""
    print("Mouse disabled")
  end
end, bufopts)

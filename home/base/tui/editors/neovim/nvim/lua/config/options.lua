-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- options
vim.o.mouse = ""                            --disable mouse
vim.g.clipboard = ""                        --disable system clipboard

vim.o.encoding = "utf-8"                    -- encoding when saving file
vim.o.fileencodings = "ucs-bom,utf-8,cp936" -- encoding when reading file

-- set wrap
vim.o.wrap = true

-- LSP Server to use for Python.
-- Set to "basedpyright" to use basedpyright instead of pyright
vim.g.lazyvim_python_lsp = "basedpyright"


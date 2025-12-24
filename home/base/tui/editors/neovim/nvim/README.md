# 💤 my-lazyvim

this project is my neovim configs that based on [LazyVim](https://github.com/LazyVim/LazyVim), and I have made some changes to it.
People who use neovim for Rust, Python or R development is recommended to use this project.

## model enabled

lazyvim.plugins.extras.coding.copilot (for copilot)

lazyvim.plugins.extras.dap.core (for debug)

## plugins added

fcitx.nvim

vim-visual-multi (multi-cursor like vscode)

nvim-ufo (fastfold)

vscode.nvim (to replace default theme)

fm-nvim (use ranger, gitui, etc in neovim)

iron.nvim (repl support)

CopilotChat.nvim (chat with copilot)

preview-R-nvim (preivew table variable in R)

## plugins disabled

alpha-nvim (I don't need and like dashbord)

mini.indentscope (replaced by nvim-treesitter and indent-blankline.nvim)

neo-tree.nvim (replaced by fm-nvim)

catppuccin (replaced by vscode.nvim) (In disabled list, it is called "nvim")

tokyonight.nvim (replaced by vscode.nvim)

nvim-notify (Too fancy)

nvim-spectre (I don't need find and replace plugins)

## feature

1. lazy load[](./screenshot/lazy_load.png)

2. lsp feature(like completion, rename, syntax checking, etc)

3. treesitter indent promt[](./screenshot/treesitter_indent_promt.png)

4. fastfold(supported by treesitter and nvim-ufo) [](./screenshot/)


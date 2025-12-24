return {
  -- dap config
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = {
      ensure_installed = { "python" },
      handlers = {
        python = function()
          local dap = require("dap")
          dap.adapters.python = {
            type = "executable",
            command = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python",
            args = { "-m", "debugpy.adapter" },
          }
          dap.configurations.python = {
            {
              type = "python",
              request = "launch",
              name = "Launch file",
              program = "${file}", -- This configuration will launch the current file if used.
              args = function()
                local input = vim.fn.input("Input args: ")
                return require("util.dap").str2argtable(input)
              end,
              pythonPath = function()
                local cwd = vim.fn.getcwd()

                -- conda env python
                local conda_py = ""
                if os.getenv("CONDA_PREFIX") ~= nil then
                  conda_py = os.getenv("CONDA_PREFIX") .. "/bin/python3"
                end

                -- check if virtualenv python exists
                if vim.fn.executable(cwd .. "/env/bin/python") == 1 then
                  return cwd .. "/env/bin/python"
                elseif vim.fn.executable(cwd .. "/.env/bin/python") == 1 then
                  return cwd .. "/.env/bin/python"
                  -- check if conda env python exists
                elseif vim.fn.executable(conda_py) == 1 then
                  return conda_py
                  -- otherwise use system python
                else
                  return "/usr/bin/python3"
                end
              end,
            },
          }
        end,
      },
    },
  },

  --repl
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

            python = {
              command = function()
                if os.getenv("CONDA_PREFIX") == nil then
                  return { "python3" }
                else
                  return { os.getenv("CONDA_PREFIX") .. "/bin/python3" }
                end
              end,
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

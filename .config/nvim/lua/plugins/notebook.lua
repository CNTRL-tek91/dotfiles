-- Jupyter notebooks, edited as normal buffers with inline output.
--
-- Two plugins doing two different jobs:
--
--   jupytext.nvim converts a .ipynb to plain text on open and back on write,
--   so the notebook is an ordinary buffer with working LSP, treesitter and
--   motions rather than raw JSON.
--
--   molten-nvim runs cells against a real jupyter kernel and renders the
--   output - including plots - inline in the buffer.
--
-- Plots work here because image.nvim is already configured for the kitty
-- graphics protocol (see plugins/editor.lua); without a backend molten would
-- show text output only.
return {
  {
    "GCBallesteros/jupytext.nvim",
    lazy = false,
    opts = {
      -- "markdown" keeps cell boundaries as ```python fences, which treesitter
      -- and the LSP both understand. The "py:percent" style writes # %% markers
      -- into a .py instead - fine for scripts, but it loses the distinction
      -- between code and prose cells on round-trip.
      style = "markdown",
      output_extension = "md",
      force_ft = "markdown",
    },
  },

  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    -- UpdateRemotePlugins is required after install or the :Molten* commands
    -- never get registered - molten is a remote plugin, so its command
    -- manifest is generated rather than declared.
    build = ":UpdateRemotePlugins",
    dependencies = { "3rd/image.nvim" },
    init = function()
      -- Jupyter writes a kernel connection file into its runtime dir, and
      -- nothing creates that directory - jupyter_client expects it to exist.
      -- On this machine ~/.local/share/jupyter existed but runtime/ inside it
      -- did not, and MoltenInit failed with
      --   "Could not initialize kernel, Caused by: Errno 2 No such file"
      -- which names no path and so points nowhere useful. Created here rather
      -- than documented as a setup step, because a missing directory is not
      -- worth a manual instruction that can be skipped on the next machine.
      vim.fn.mkdir(vim.fn.expand("~/.local/share/jupyter/runtime"), "p")

      -- Must be set BEFORE the plugin loads; molten reads these at startup.
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 20
      -- Show output in a floating window under the cell rather than taking a
      -- permanent split, so a long notebook stays readable.
      vim.g.molten_auto_open_output = false
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true
      -- Wrap long output instead of truncating it - tracebacks are the main
      -- thing you read in a notebook and they are wide.
      vim.g.molten_wrap_output = true
    end,
    keys = {
      { "<leader>ji", "<cmd>MoltenInit<cr>", desc = "Notebook: init kernel" },
      { "<leader>je", "<cmd>MoltenEvaluateOperator<cr>", desc = "Notebook: evaluate operator" },
      { "<leader>jl", "<cmd>MoltenEvaluateLine<cr>", desc = "Notebook: evaluate line" },
      { "<leader>jc", "<cmd>MoltenReevaluateCell<cr>", desc = "Notebook: re-evaluate cell" },
      { "<leader>jd", "<cmd>MoltenDelete<cr>", desc = "Notebook: delete cell output" },
      { "<leader>jo", "<cmd>MoltenShowOutput<cr>", desc = "Notebook: show output" },
      { "<leader>jh", "<cmd>MoltenHideOutput<cr>", desc = "Notebook: hide output" },
      { "<leader>jv", ":<C-u>MoltenEvaluateVisual<cr>gv", mode = "x", desc = "Notebook: evaluate selection" },
    },
  },

  {
    "folke/which-key.nvim",
    optional = true,
    opts = { spec = { { "<leader>j", group = "jupyter/notebook" } } },
  },
}

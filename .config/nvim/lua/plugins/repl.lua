-- A live REPL you send code to, rather than re-running a whole file.
--
-- This is the workflow <leader>or cannot give you. Running a file starts a
-- fresh interpreter every time, so anything expensive at import - loading a
-- model, reading a dataset, importing torch - is paid again on every edit. A
-- REPL keeps that state and lets you send one line, a selection, or a marked
-- cell into it.
--
-- iron.nvim over vim-slime or a bare :terminal because it manages the REPL
-- window itself (one per filetype, reopened on demand) instead of asking you
-- to target a pane by hand.
return {
  {
    "Vigemus/iron.nvim",
    -- Loading on the keys, not on ft: the REPL is also useful from a buffer
    -- that is not Python, and lazy.nvim will pull it in on first use either way.
    keys = {
      { "<leader>rr", "<cmd>IronRepl<cr>", desc = "REPL: toggle" },
      { "<leader>rR", "<cmd>IronRestart<cr>", desc = "REPL: restart" },
      { "<leader>rl", function() require("iron.core").send_line() end, desc = "REPL: send line" },
      { "<leader>rb", function() require("iron.core").send_file() end, desc = "REPL: send whole file" },
      { "<leader>rm", function() require("iron.core").send_mark() end, desc = "REPL: send mark" },
      { "<leader>rq", function() require("iron.core").close_repl() end, desc = "REPL: quit" },
      -- Visual mode: send exactly what is selected. The most-used binding of
      -- the set in practice.
      { "<leader>rv", function() require("iron.core").visual_send() end, mode = "x", desc = "REPL: send selection" },
    },
    config = function()
      local iron = require("iron.core")

      iron.setup({
        config = {
          -- Keep the REPL process alive when its window is closed, so toggling
          -- the window away does not throw away loaded state - the entire point
          -- of using a REPL over re-running the file.
          scratch_repl = true,
          repl_definition = {
            python = {
              -- ipython, not python: it echoes input, handles pasted blocks
              -- with correct indentation, and gives real tracebacks. Plain
              -- python's REPL mangles multi-line indented pastes.
              --
              -- Resolved at call time rather than hardcoded, so it follows the
              -- venv the same way lua/util/run.lua does: $VIRTUAL_ENV first,
              -- then a project .venv, then whatever is on PATH.
              command = function()
                local venv = vim.env.VIRTUAL_ENV
                if not venv or venv == "" then
                  local ok, root = pcall(function()
                    return LazyVim.root()
                  end)
                  if ok and root then
                    for _, name in ipairs({ ".venv", "venv" }) do
                      if vim.uv.fs_stat(root .. "/" .. name .. "/bin/python") then
                        venv = root .. "/" .. name
                        break
                      end
                    end
                  end
                end
                if venv and venv ~= "" then
                  for _, exe in ipairs({ "/bin/ipython", "/bin/python" }) do
                    if vim.uv.fs_stat(venv .. exe) then
                      return { venv .. exe }
                    end
                  end
                end
                return { vim.fn.executable("ipython") == 1 and "ipython" or "python3" }
              end,
              -- Wrap pasted blocks in bracketed paste so ipython treats them as
              -- one unit instead of auto-indenting each line against the last.
              format = require("iron.fts.common").bracketed_paste_python,
            },
          },
          -- A real bottom SPLIT, matching where <leader>or puts its output, so
          -- code and interpreter occupy the same part of the screen either way.
          --
          -- Not view.bottom(15): that returns a floating window pinned to the
          -- bottom edge, which covers the code rather than sitting beside it.
          -- Verified - it came back with relative="editor" (a float). A plain
          -- vim split command is what actually splits.
          repl_open_cmd = "belowright 15 split",
        },
        -- iron's own in-REPL keymaps are left off; the <leader>r set above is
        -- the whole interface, and defining them twice invites drift.
        keymaps = {},
        highlight = { italic = false },
        ignore_blank_lines = true,
      })
    end,
  },
}

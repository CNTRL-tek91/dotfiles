-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local augroup = vim.api.nvim_create_augroup("cntrl", { clear = true })

-- kitty.conf sets window_padding_width 10, which looks right for a shell but
-- wastes screen edge in a full-screen editor. Drop it to 0 for the duration of
-- the session and put it back on exit.
--
-- kitty exports KITTY_LISTEN_ON to processes running inside it, and that is
-- exactly the condition under which `kitty @` can reach the window - so it
-- doubles as the "are we actually in kitty" test. nvim-custom ran this
-- unguarded behind `:silent !`, which meant it failed invisibly in any other
-- terminal rather than not running at all.
local function kitty_padding(px)
  if not vim.env.KITTY_LISTEN_ON then
    return
  end
  -- Synchronous on purpose: an async call from VimLeavePre races the exit and
  -- the padding never comes back.
  vim.fn.system({ "kitty", "@", "set-spacing", "padding=" .. px })
end

vim.api.nvim_create_autocmd("VimEnter", {
  group = augroup,
  desc = "Remove kitty's window padding while nvim is open",
  callback = function()
    kitty_padding(0)
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = augroup,
  desc = "Restore kitty's window padding on exit",
  callback = function()
    kitty_padding(10)
  end,
})

-- NOT carried over from nvim-custom: a BufEnter autocmd that :cd'd into every
-- file's own directory. It existed to stop compiler.nvim refusing to run in
-- $HOME, but it fights LazyVim head on - LazyVim resolves a project root
-- (vim.g.root_spec = lsp, then .git/lua, then cwd) and feeds it to the pickers,
-- grep and terminal. Constantly rewriting cwd would silently shrink a
-- project-wide <leader>/ search down to one directory. LazyVim's root
-- detection solves the original problem properly, so the workaround is gone.

-- Python indentation inside notebook code cells.
--
-- jupytext sets force_ft = "markdown" so a notebook is one markdown buffer -
-- that is what makes prose cells and rendering work - but Enter after
-- `def main():` left the cursor in column 0.
--
-- Note this is specific to jupytext's buffers, not to markdown. A plain .md
-- opened as the first buffer of a session already carries
-- indentexpr=v:lua.LazyVim.treesitter.indentexpr(); a notebook built by
-- jupytext's BufReadCmd comes up with indentexpr empty, so it loses the
-- indentation ordinary markdown gets. Restoring it is half the fix.
--
-- Measured in a cell, Enter after `def main():`:
--
--   notebook as jupytext leaves it (no indentexpr)   0 columns
--   shiftwidth = 4 alone                             0 columns
--   shiftwidth = 4 + treesitter indentexpr           4 columns
--
-- The expression gives python-aware indent because treesitter injects python
-- into ```python fences (parser:children() reports markdown_inline and
-- python), so the indent query runs against a real python tree. shiftwidth is
-- the other half: markdown's 2 produces 2-column python, which is why prose
-- notes are deliberately left alone below rather than also set to 4.
--
-- Beware a false positive when testing this: `smartindent` indents after
-- `if`/`for`/`while` on its own because those are 'cinwords', so the setup
-- looks like it works until you try `def`.
--
-- This lives here rather than in the jupytext plugin spec on purpose. That
-- spec already uses init() for the .ipynb repair guard, and lazy.nvim merges
-- two fragments of one plugin by overwriting function fields - a second init()
-- silently replaced the guard and brought the crash straight back.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown" },
  group = vim.api.nvim_create_augroup("notebook_python_indent", { clear = true }),
  callback = function(ev)
    -- Notebooks only. Ordinary markdown notes keep markdown's indentation,
    -- where a 4-column bump fights list nesting.
    if not vim.api.nvim_buf_get_name(ev.buf):match("%.ipynb$") then
      return
    end
    -- Applied after the ftplugin: this autocommand is registered later than
    -- filetype.vim's, and FileType handlers run in registration order.
    vim.bo[ev.buf].shiftwidth = 4
    vim.bo[ev.buf].expandtab = true
    vim.bo[ev.buf].indentexpr = "v:lua.LazyVim.treesitter.indentexpr()"
  end,
})

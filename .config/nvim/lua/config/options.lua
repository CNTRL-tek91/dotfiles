-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
--
-- Only the deltas from LazyVim's defaults live here. Anything the old
-- nvim-custom config set that LazyVim already sets identically (expandtab,
-- shiftwidth/tabstop 2, ignorecase, smartcase, number, relativenumber,
-- termguicolors, smartindent, splitbelow, splitright, splitkeep, undofile,
-- signcolumn, laststatus 3, nowrap, fillchars eob) is deliberately not
-- repeated - duplicating it would just create a second place to keep in sync.

-- LazyVim's python extra defaults to pyright. nvim-custom used basedpyright
-- (it is what mason installed there), and basedpyright is the stricter fork
-- with better inference, so keep it. Without this the configured server is
-- pyright, which is not installed - leaving python with only ruff attached and
-- no type checking or completion at all.
vim.g.lazyvim_python_lsp = "basedpyright"

local opt = vim.opt

-- More context around the cursor than LazyVim's 4/8. Carried over from
-- nvim-custom; the horizontal one matters on the ultrawide external monitor.
opt.scrolloff = 10
opt.sidescrolloff = 40

-- Right margin marker at the PEP 8 / black line length.
opt.colorcolumn = "79"

-- Undo history is persisted (undofile, on by default in LazyVim), so swap
-- files only ever produced stale-swap prompts after a crash.
opt.swapfile = false

-- LazyVim uses "nosplit". The split preview shows every match at once, which
-- is the whole point of previewing a :%s before committing to it.
opt.inccommand = "split"

-- LazyVim leaves softtabstop at 0, which makes <BS> in leading whitespace
-- delete one space instead of a full indent level.
opt.softtabstop = 2

-- .http files are request collections handled by kulala.
vim.filetype.add({
  extension = {
    ["http"] = "http",
  },
})

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

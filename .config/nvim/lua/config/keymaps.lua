-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--
-- Only personal keymaps that LazyVim does not already provide live here.
-- Window navigation (<C-h/j/k/l>), window resizing (<C-Up/Down/Left/Right>)
-- and buffer cycling (<S-h>/<S-l>) were in nvim-custom and are LazyVim
-- defaults with identical bindings, so they are not repeated.
--
-- Keymaps that belong to a specific plugin are defined in that plugin's spec
-- under lua/plugins/, not here, so removing the plugin removes its keys too.

local map = vim.keymap.set

-- Exit insert mode without reaching for Escape.
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- LazyVim v16 has no file explorer until you enable one; lazyvim.json turns on
-- the editor.snacks_explorer extra, which binds <leader>e (root) and
-- <leader>E (cwd). <C-n> is the toggle nvim-custom used for nvim-tree, kept
-- because it is muscle memory and LazyVim leaves <C-n> free.
map("n", "<C-n>", function()
  Snacks.explorer({ cwd = LazyVim.root() })
end, { desc = "Explorer (toggle)" })

-- Close the current buffer without closing its window. LazyVim has this on
-- <leader>bd; <A-w> is the nvim-custom binding, kept as a second way in.
map("n", "<A-w>", function()
  Snacks.bufdelete()
end, { desc = "Delete buffer" })

-- LazyVim's terminal toggle is <C-/>. <C-\> was the toggleterm binding in
-- nvim-custom and is otherwise unused, so it stays as an alias.
map("n", "<C-\\>", function()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (root dir)" })

-- Run the current file. These sit in the <leader>o (overseer) group because
-- that is where "make something happen with this code" already lives, and
-- because the obvious <leader>cr / <leader>cR are both taken - LazyVim binds
-- them to LSP rename and rename-file, and inc-rename rebinds <leader>cr again.
-- Overseer keeps <leader>oo / <leader>ot / <leader>ow; or/oR/ob are free.
local function run(opts)
  return function()
    require("util.run").run(opts)
  end
end

map("n", "<leader>or", run(), { desc = "Run current file" })
map("n", "<leader>oR", run({ prompt = true }), { desc = "Run current file (with args)" })
map("n", "<leader>ob", run({ compile_only = true }), { desc = "Build current file (no run)" })

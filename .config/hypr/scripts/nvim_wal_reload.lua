-- Re-read pywal's palette and re-apply the colorscheme in a RUNNING nvim.
--
-- Executed by reload_nvim_theme.sh via nvim's remote API, once per live
-- instance, after the wallpaper theme changes. Kept as a standalone file rather
-- than a config-defined command so it works in whichever config is loaded -
-- LazyVim or nvim-custom - without either having to define anything.
--
-- lushwal ships its own fs_event watcher on ~/.cache/wal/colors.json, but it is
-- not dependable: the theming pipeline rewrites that file twice per change
-- (once by extract_accents.py, once when `wal --theme` regenerates it), a
-- single-file watch does not survive the file being replaced, and the watcher
-- only re-arms after an event it actually received - so one missed event stops
-- it for the rest of the session. Pushing the reload instead of waiting for it
-- to be noticed removes that whole class of failure.
local ok, lushwal = pcall(require, "lushwal")
if not ok then
  return
end

-- Only act when the wallpaper theme is the one in use. If a different
-- colorscheme was chosen deliberately with <leader>uC, changing the wallpaper
-- should not yank it away.
if vim.g.colors_name ~= "lushwal" then
  return
end

-- Drop lushwal's cached colour modules first. Its addons - the per-plugin
-- highlight generators for lualine, bufferline, gitsigns and so on - open with
--     local colors = require("lushwal").colors
-- at module scope, which Lua evaluates exactly once and then caches in
-- package.loaded. Without clearing them, reload_theme rebuilds those plugins
-- from the ORIGINAL palette forever: syntax highlighting updates (it comes from
-- the scheme itself) while the statusline and bufferline silently keep the old
-- colours. That splits the theme in half and reads as "the theme didn't
-- change", because the statusline is the most colourful thing on screen.
for name, _ in pairs(package.loaded) do
  if name == "lushwal.colors" or name:match("^lushwal%.addons%.") then
    package.loaded[name] = nil
  end
end

-- reload_theme re-reads the palette, re-applies the colorscheme and runs
-- lushwal's own reload hooks. transparent.nvim re-clears backgrounds off the
-- resulting ColorScheme event, so transparency survives without extra work.
pcall(lushwal.reload_theme)

-- lualine caches its resolved theme at setup and rebuilds it from its own
-- ColorScheme autocmd. That autocmd has already fired by now, while the addon
-- modules above were still cached, so re-run setup to pick up the fresh ones.
pcall(function()
  require("lualine").setup()
end)

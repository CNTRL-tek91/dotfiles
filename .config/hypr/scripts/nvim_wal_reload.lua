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

-- reload_theme re-reads the palette, re-applies the colorscheme and runs
-- lushwal's own reload hooks. transparent.nvim re-clears backgrounds off the
-- resulting ColorScheme event, so transparency survives without extra work.
pcall(lushwal.reload_theme)

-- File where the last-selected colorscheme is remembered between sessions.
local persist_file = vim.fn.stdpath("data") .. "/last-colorscheme.txt"

-- lushwal is the pywal-driven theme; applying it also wires up its reload hook
-- and enables transparency. tokyonight is the safe fallback if lushwal is
-- missing or fails to load.
local function apply_lushwal_or_fallback()
  local status_ok, lushwal = pcall(require, "lushwal")
  if status_ok then
    local setup_ok = pcall(function()
      vim.cmd("colorscheme lushwal")
      lushwal.add_reload_hook({
        vim.cmd("LushwalCompile"),
      })
      vim.cmd("TransparentEnable")
    end)
    if setup_ok then
      return
    end
  end
  vim.cmd("colorscheme tokyonight")
end

-- Read the remembered colorscheme name, if one was saved.
local function read_saved()
  local f = io.open(persist_file, "r")
  if not f then
    return nil
  end
  local name = f:read("*l")
  f:close()
  if name and name ~= "" then
    return name
  end
  return nil
end

-- Save a colorscheme name so it is restored on the next launch.
local function save(name)
  local f = io.open(persist_file, "w")
  if f then
    f:write(name)
    f:close()
  end
end

-- On startup, restore the last theme you chose. With no saved choice (fresh
-- setup) — or if the saved one is lushwal — use the pywal theme as before.
local saved = read_saved()
if saved == nil or saved == "lushwal" then
  apply_lushwal_or_fallback()
elseif not pcall(vim.cmd, "colorscheme " .. saved) then
  -- Saved theme no longer installed / errored: fall back gracefully.
  apply_lushwal_or_fallback()
end

-- Registered AFTER the startup apply above, so the initial theme isn't written
-- back (keeps lushwal as the default on a fresh setup). From here on, any theme
-- change — e.g. via `:Telescope colorscheme` (<leader>th) or `:colorscheme` —
-- is remembered for next time.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("persist_colorscheme", { clear = true }),
  callback = function(args)
    if args.match and args.match ~= "" then
      save(args.match)
    end
  end,
})

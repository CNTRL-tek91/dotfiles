-- Wallpaper-driven theming.
--
-- Every other surface on this desktop (waybar, kitty, hyprland, dunst, ...) is
-- recoloured from the wallpaper by pywal/wallust. lushwal is the Neovim end of
-- that pipeline: it builds a colorscheme from pywal's ~/.cache/wal output, so
-- the editor matches whatever wallpaper - static or live - is currently up.
-- Losing this is the one thing that would make LazyVim look wrong here, so it
-- is ported deliberately rather than left to LazyVim's tokyonight default.
--
-- Colours refresh on the next launch, exactly as they did before: pywal writes
-- the cache when the wallpaper changes, and lushwal reads it at startup.

-- Remembers the last colorscheme chosen with <leader>uC so it survives a
-- restart. stdpath("data") is per-NVIM_APPNAME, so this file is LazyVim's own
-- and cannot collide with the one nvim-custom keeps.
local persist_file = vim.fn.stdpath("data") .. "/last-colorscheme.txt"

local function read_saved()
  local f = io.open(persist_file, "r")
  if not f then
    return nil
  end
  local name = f:read("*l")
  f:close()
  return (name and name ~= "") and name or nil
end

local function save(name)
  local f = io.open(persist_file, "w")
  if f then
    f:write(name)
    f:close()
  end
end

-- Transparency is NOT applied from here. transparent.nvim installs its own
-- VimEnter/ColorScheme/FileType autocmds, so once it is enabled it re-clears
-- the background after every theme change on its own - including switches made
-- later with <leader>uC. Calling :TransparentEnable from this function instead
-- looked like it worked and did nothing: LazyVim applies the colorscheme
-- before lower-priority start plugins load, so the command did not exist yet
-- and the pcall swallowed the error.
local function apply_lushwal()
  return pcall(function()
    vim.cmd("colorscheme lushwal")
    -- nvim-custom called this as add_reload_hook({ vim.cmd("LushwalCompile") }),
    -- which ran the command once immediately and then registered a table.
    -- lushwal's run_hooks only dispatches string and function hooks, so the
    -- table was silently dropped and the hook never fired again. A plain
    -- string is the form the API actually handles.
    require("lushwal").add_reload_hook("LushwalCompile")
  end)
end

return {
  {
    "oncomouse/lushwal.nvim",
    -- Not lazy: it is the startup colorscheme, and a colorscheme that loads
    -- late means a visible flash of the fallback theme first.
    lazy = false,
    priority = 1000,
    cmd = { "LushwalCompile" },
    dependencies = {
      { "rktjmp/lush.nvim" },
      { "rktjmp/shipwright.nvim" },
    },
    config = function()
      vim.g.lushwal_configuration = {
        compile_to_vimscript = false,
        -- Addons are per-plugin highlight groups. This list is retargeted from
        -- nvim-custom's onto LazyVim v16's actual plugin set - enabling an
        -- addon for a plugin that isn't installed just generates dead
        -- highlights, and the four turned off below are exactly that:
        --   indent_blankline -> LazyVim uses snacks indent
        --   nvim_tree_lua    -> LazyVim uses the snacks explorer
        --   telescope_nvim   -> LazyVim v16's picker is snacks
        --   nvim_cmp         -> LazyVim v16 completes with blink.cmp
        addons = {
          bufferline_nvim = true,
          gitsigns_nvim = true,
          lualine = true,
          which_key_nvim = true,
          markdown = true,
          lsp_trouble_nvim = true,
          native_lsp = true,
          treesitter = true,
          indent_blankline_nvim = false,
          nvim_tree_lua = false,
          telescope_nvim = false,
          nvim_cmp = false,
        },
      }
    end,
  },

  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    priority = 999,
    opts = {
      -- `groups` is left at the plugin's default. nvim-custom listed it out in
      -- full, but that list was identical to the default - these three are the
      -- only real additions.
      extra_groups = { "VertSplit", "Float", "NormalFloat" },
    },
    config = function(_, opts)
      local transparent = require("transparent")
      transparent.setup(opts)
      -- Plugin windows that should keep their own background rather than
      -- showing the wallpaper through them. Retargeted from nvim-custom's
      -- list: NvimTree and barbecue are gone, replaced by the snacks windows
      -- and navic breadcrumbs that LazyVim uses instead.
      for _, prefix in ipairs({ "BufferLine", "Snacks", "WhichKey", "Navic", "Lazy", "Mason", "Trouble" }) do
        transparent.clear_prefix(prefix)
      end
      -- kitty runs at background_opacity 0.8, so an opaque editor background
      -- would punch a solid rectangle through an otherwise translucent
      -- desktop. toggle(true) sets the flag, persists it to transparent.nvim's
      -- cache and re-applies the current colorscheme so the clear takes effect
      -- immediately - and it runs here, where the plugin is guaranteed loaded.
      transparent.toggle(true)
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        local saved = read_saved()

        -- No saved choice, or lushwal explicitly saved: use the wallpaper
        -- theme. Anything else was picked deliberately, so honour it and only
        -- fall back to lushwal if it fails to load.
        if saved == nil or saved == "lushwal" then
          if not apply_lushwal() then
            vim.cmd("colorscheme tokyonight")
          end
        elseif pcall(vim.cmd, "colorscheme " .. saved) then
          -- saved theme loaded fine
        elseif not apply_lushwal() then
          vim.cmd("colorscheme tokyonight")
        end

        -- Registered only after the startup apply, so the initial theme is not
        -- written back - that keeps lushwal the default on a fresh install
        -- instead of persisting whatever the first fallback happened to be.
        vim.api.nvim_create_autocmd("ColorScheme", {
          group = vim.api.nvim_create_augroup("persist_colorscheme", { clear = true }),
          callback = function(args)
            if args.match and args.match ~= "" then
              save(args.match)
            end
          end,
        })
      end,
    },
  },
}

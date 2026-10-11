-- Guarantee readable text on highlight groups that paint a background.
--
-- The wallpaper-driven palette puts some backgrounds at a mid-tone lightness,
-- and a mid-tone is the worst case: it is too dark for the palette's light
-- foreground and too light for its dark one, so BOTH choices of text colour
-- fail. Measured on one wallpaper:
--
--   LspReference  fg #15090b on bg #79676a  ->  3.68   (what shipped)
--                 fg #c3c1c1 on bg #79676a  ->  2.96   (naive "use light fg")
--
-- So flipping the foreground makes it worse. What works is keeping the light
-- foreground and DARKENING the background, preserving its hue and saturation
-- so the theme still reads as wallpaper-derived:
--
--   fg #c3c1c1 on bg #5a4c4e  ->  4.54
--
-- LspReference* is the group the illuminate extra uses for the symbol under
-- the cursor and its other occurrences, which is why text appeared to go dark
-- the moment the cursor landed on a word.
--
-- Same 4.5 WCAG floor the accent extractor already enforces (MIN_CONTRAST in
-- extract_accents.py), so the two halves of the theming agree on "readable".
local M = {}

local TARGET = 4.5

local function lin(c)
  c = c / 255
  return c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
end

local function luminance(rgb)
  local r = bit.rshift(bit.band(rgb, 0xFF0000), 16)
  local g = bit.rshift(bit.band(rgb, 0x00FF00), 8)
  local b = bit.band(rgb, 0x0000FF)
  return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
end

local function contrast(a, b)
  local la, lb = luminance(a), luminance(b)
  local hi, lo = math.max(la, lb), math.min(la, lb)
  return (hi + 0.05) / (lo + 0.05)
end

-- Scale RGB toward black. Multiplying all three channels by the same factor
-- preserves hue and saturation exactly, which a HSL round-trip does not
-- guarantee at low lightness.
local function scale(rgb, f)
  local r = math.floor(bit.rshift(bit.band(rgb, 0xFF0000), 16) * f + 0.5)
  local g = math.floor(bit.rshift(bit.band(rgb, 0x00FF00), 8) * f + 0.5)
  local b = math.floor(bit.band(rgb, 0x0000FF) * f + 0.5)
  return r * 65536 + g * 256 + b
end

local function darken_until(bg, fg)
  for step = 0, 100 do
    local cand = scale(bg, 1 - step / 100)
    if contrast(fg, cand) >= TARGET then
      return cand
    end
  end
  return 0x000000
end

-- Raise a foreground toward white until it is legible on `bg`.
--
-- Interpolating toward white rather than scaling channels up: scaling
-- multiplies the channels, which drives an already-bright channel to 255 first
-- and shifts the hue as the others catch up. Mixing toward white moves all
-- three in step, so the hue is preserved and only saturation drops - the colour
-- reads as a paler version of itself rather than a different one.
local function lighten_until(fg, bg)
  local r0 = bit.rshift(bit.band(fg, 0xFF0000), 16)
  local g0 = bit.rshift(bit.band(fg, 0x00FF00), 8)
  local b0 = bit.band(fg, 0x0000FF)
  for step = 0, 100 do
    local t = step / 100
    local r = math.floor(r0 + (255 - r0) * t + 0.5)
    local g = math.floor(g0 + (255 - g0) * t + 0.5)
    local b = math.floor(b0 + (255 - b0) * t + 0.5)
    local cand = r * 65536 + g * 256 + b
    if contrast(cand, bg) >= TARGET then
      return cand
    end
  end
  return 0xFFFFFF
end

-- Groups that paint a BACKGROUND behind ordinary text. These get the palette's
-- own foreground plus a background darkened until it is legible.
M.groups = {
  "Visual",
  "LspReferenceText",
  "LspReferenceRead",
  "LspReferenceWrite",
  "IlluminatedWordText",
  "IlluminatedWordRead",
  "IlluminatedWordWrite",
  "Search",
  "IncSearch",
  "CurSearch",
  "MatchParen",
  "Folded",
}

-- Groups that are a FOREGROUND only - ordinary syntax colour on the editor
-- background. These were the gap: the first version of this module only handled
-- backgrounds, and on a wallpaper that produced dim mid-tone accents 12 of
-- these measured below 4.5, including @variable and @parameter at 3.87 (the
-- most common tokens in a Python file) and DiagnosticError at 3.28.
--
-- Treesitter captures are listed explicitly rather than discovered: nvim_get_hl
-- with link=false does not resolve a capture that only inherits, so walking
-- every highlight would mostly return empty tables.
M.fg_groups = {
  "Comment", "String", "Character", "Number", "Float", "Boolean", "Constant",
  "Identifier", "Function", "Statement", "Conditional", "Repeat", "Label",
  "Operator", "Keyword", "Exception", "PreProc", "Include", "Define", "Macro",
  "Type", "StorageClass", "Structure", "Typedef", "Special", "SpecialChar",
  "Delimiter", "SpecialComment", "Debug", "Todo",
  "@variable", "@variable.builtin", "@variable.parameter", "@variable.member",
  "@parameter", "@property", "@field", "@constant", "@constant.builtin",
  "@string", "@string.escape", "@number", "@boolean", "@function",
  "@function.builtin", "@function.call", "@method", "@keyword", "@type",
  "@type.builtin", "@comment", "@operator", "@punctuation.bracket",
  "@punctuation.delimiter", "@constructor", "@namespace", "@module",
  "DiagnosticError", "DiagnosticWarn", "DiagnosticInfo", "DiagnosticHint",
  "LineNr", "SignColumn", "WinBar", "NonText",
}

function M.apply()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local fg = normal.fg
  if not fg then
    return
  end
  -- transparent.nvim clears Normal's background, so this is usually 0 (the
  -- terminal's own background shows through). Black is the right reference for
  -- a dark terminal; on a light one these sums would need inverting.
  local bg = normal.bg or 0x000000

  -- Pass 1: groups with a background of their own.
  for _, name in ipairs(M.groups) do
    local h = vim.api.nvim_get_hl(0, { name = name, link = false })
    if h.bg and contrast(fg, h.bg) < TARGET then
      h.fg = fg
      h.bg = darken_until(h.bg, fg)
      h.reverse = false
      vim.api.nvim_set_hl(0, name, h)
    end
  end

  -- Pass 2: foreground-only groups. Skipped when the group also has a
  -- background, because pass 1 already owns that case and re-lifting the
  -- foreground here would fight it.
  for _, name in ipairs(M.fg_groups) do
    local h = vim.api.nvim_get_hl(0, { name = name, link = false })
    if h.fg and not h.bg and contrast(h.fg, bg) < TARGET then
      h.fg = lighten_until(h.fg, bg)
      vim.api.nvim_set_hl(0, name, h)
    end
  end
end

return M

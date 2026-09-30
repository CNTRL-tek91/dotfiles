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

-- Groups that paint a background behind ordinary text. Anything here gets the
-- palette's own foreground plus a background darkened until it is legible.
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

function M.apply()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local fg = normal.fg
  if not fg then
    return
  end

  for _, name in ipairs(M.groups) do
    local h = vim.api.nvim_get_hl(0, { name = name, link = false })
    -- Only groups that actually have a background are in scope; one without a
    -- background inherits Normal's and is already fine.
    if h.bg then
      if contrast(fg, h.bg) < TARGET then
        h.fg = fg
        h.bg = darken_until(h.bg, fg)
        h.reverse = false
        vim.api.nvim_set_hl(0, name, h)
      end
    end
  end
end

return M

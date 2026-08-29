-- Disabled: luarocks.nvim built a private LuaRocks tree to install the `magick`
-- rock for image.nvim, but the build never succeeded (no system luarocks; the
-- .rocks tree stayed empty) and it printed "Unable to load the luarocks package
-- loader" on every startup. image.nvim is now configured with
-- `processor = "magick_cli"` (see image.lua), which uses the ImageMagick CLI and
-- needs no rock, so this plugin is no longer required.
return {}

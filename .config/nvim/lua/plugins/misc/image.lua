return {
  "3rd/image.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    -- Use the ImageMagick CLI (/usr/bin/magick) directly instead of the
    -- `magick` luarock. This removes the need for luarocks.nvim, whose rock
    -- build was failing on every startup.
    processor = "magick_cli",
    integrations = {
      markdown = { only_render_image_at_cursor = true },
    },
  },
}

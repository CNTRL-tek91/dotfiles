-- Plugins carried over from the nvim-custom config that LazyVim has no
-- equivalent for. Anything LazyVim or one of its extras already covers is not
-- duplicated here - see lazyvim.json for the extras that replaced the rest.

return {
  -- Inline images in the buffer. This is the reason kitty is the terminal:
  -- image.nvim renders through the kitty graphics protocol.
  {
    "3rd/image.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- The ImageMagick CLI directly, rather than the `magick` luarock. The
      -- rock's build failed on every startup in nvim-custom and needed
      -- luarocks.nvim + hererocks to paper over; magick_cli needs neither, and
      -- /usr/bin/magick is already installed for the wallpaper theming.
      processor = "magick_cli",
      integrations = {
        markdown = { only_render_image_at_cursor = true },
      },
    },
  },

  -- LSP inside embedded code blocks (fenced code in markdown, SQL in strings).
  {
    "jmbuhr/otter.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = true,
  },
}

return {
  -- Screenshot a visual selection as a styled image. Settings are the ones
  -- tuned in nvim-custom, including the save path under ~/Pictures.
  {
    "mistricky/codesnap.nvim",
    build = "make",
    cmd = { "CodeSnap", "CodeSnapSave" },
    keys = {
      { "<leader>cc", "<cmd>CodeSnap<cr>", mode = "x", desc = "Code screenshot (clipboard)" },
      { "<leader>cS", "<cmd>CodeSnapSave<cr>", mode = "x", desc = "Code screenshot (save to file)" },
    },
    opts = {
      save_path = "~/Pictures/screenshots/code",
      border = "rounded",
      has_breadcrumbs = false,
      has_line_number = true,
      bg_theme = "grape",
      bg_x_padding = 122,
      bg_y_padding = 52,
      bg_padding = nil,
      watermark = "",
    },
  },

  -- Translate text in place.
  {
    "potamides/pantran.nvim",
    cmd = "Pantran",
    keys = {
      { "<leader>cT", "<cmd>Pantran<cr>", mode = { "n", "x" }, desc = "Translate" },
    },
    opts = { default_engine = "yandex" },
  },
}

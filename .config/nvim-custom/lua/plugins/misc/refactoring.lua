return {
  "ThePrimeagen/refactoring.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    -- refactoring.nvim now does `require "async"` internally; that module is
    -- provided by this plugin. Without it, the config errors on startup.
    "lewis6991/async.nvim",
  },
  opts = { show_success_message = true },
}

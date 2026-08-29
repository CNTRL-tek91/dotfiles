return {
  -- Only colours colorcolumn as you approach it, instead of a permanent stripe
  -- down the buffer. Pairs with the colorcolumn = 79 set in config/options.lua.
  {
    "Bekaboo/deadcolumn.nvim",
    event = { "BufReadPre", "BufNewFile" },
  },

  -- Brief highlight on yank/paste/undo so it is obvious what just changed.
  {
    "rachartier/tiny-glimmer.nvim",
    event = "VeryLazy",
    config = true,
  },

  -- Matching brackets coloured by nesting depth.
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPre", "BufNewFile" },
  },
}

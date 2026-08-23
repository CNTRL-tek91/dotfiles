return {
  "nvim-telescope/telescope.nvim",
  event = "VeryLazy",
  dependencies = {
    { "nvim-lua/plenary.nvim" },
    -- Compiled C fuzzy sorter: faster filtering + fzf query syntax ('exact, ^prefix, suffix$).
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    { "nvim-telescope/telescope-ui-select.nvim" },
    { "piersolenski/telescope-import.nvim" },
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      pickers = {
        find_files = { hidden = true },
        colorscheme = {
          enable_preview = true,
          ignore_builtins = true,
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
        ["ui-select"] = { require("telescope.themes").get_dropdown({}) },
        import = { insert_at_top = true },
      },
      defaults = {
        file_ignore_patterns = {
          "venv",
          ".venv",
          "node_modules",
        },
        prompt_prefix = " ",
        selection_caret = "󱞩 ",
        path_display = { "smart" },
        layout_config = {
          vertical = {
            preview_cutoff = 0,
            preview_height = 0.5,
          },
          horizontal = {
            preview_cutoff = 0,
            preview_width = 0.6,
          },
        },
      },
    })
    telescope.load_extension("fzf")
    telescope.load_extension("ui-select")
    telescope.load_extension("import")
  end,
}

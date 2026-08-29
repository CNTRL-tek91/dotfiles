return {
  -- Side-by-side diffs and file history. LazyVim covers hunks (gitsigns) and
  -- general git work (<leader>gg, lazygit), but has nothing for reviewing a
  -- whole branch diff or walking one file's history.
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gdo", "<cmd>DiffviewOpen<cr>", desc = "Diffview open" },
      { "<leader>gdc", "<cmd>DiffviewClose<cr>", desc = "Diffview close" },
      { "<leader>gdf", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview file history" },
    },
  },
}

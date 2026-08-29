return {
  "nvimtools/none-ls.nvim",
  event = { "InsertEnter", "BufReadPre", "InsertLeave" },
  config = function()
    local null_ls = require("null-ls")
    null_ls.setup({
      sources = {
        -- Lua
        null_ls.builtins.formatting.stylua.with({
          -- stdpath("config") follows NVIM_APPNAME, so this resolves to this
          -- config's own directory whether it is loaded as ~/.config/nvim or
          -- as ~/.config/nvim-custom. Hardcoding ~/.config/nvim broke the
          -- moment LazyVim took that path over.
          extra_args = { "--config-path", vim.fn.stdpath("config") .. "/tool_configs/stylua.toml" },
        }),
        -- JavaScript, TypeScript, JSX, TSX, JSON, CSS and GraphQL
        null_ls.builtins.formatting.prettierd,
        -- null_ls.builtins.formatting.biome,
        null_ls.builtins.diagnostics.stylelint,
        -- Shell
        null_ls.builtins.formatting.shfmt.with({ extra_args = { "-i", "2", "-ci" } }),
        -- Dockerfile
        null_ls.builtins.diagnostics.hadolint,
      },
    })
  end,
}

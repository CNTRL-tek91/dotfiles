return {
  -- The ruff settings carried over from nvim-custom: line-length 79 (matching
  -- the colorcolumn in config/options.lua), single quotes, and a wider rule
  -- selection than ruff's default E/F.
  --
  -- Note this is a *global* default handed to the LSP, so it also applies in
  -- projects that ship their own ruff.toml or pyproject.toml [tool.ruff]. If
  -- you would rather per-project config win, delete this spec - LazyVim's
  -- python extra then leaves ruff to discover config the normal way.
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local ruff_config = vim.fn.stdpath("config") .. "/tool_configs/ruff.toml"
      opts.servers = opts.servers or {}
      opts.servers.ruff = vim.tbl_deep_extend("force", opts.servers.ruff or {}, {
        init_options = {
          settings = {
            format = { args = { "--config=" .. ruff_config } },
            lint = { args = { "--config=" .. ruff_config } },
          },
        },
      })
      return opts
    end,
  },
}

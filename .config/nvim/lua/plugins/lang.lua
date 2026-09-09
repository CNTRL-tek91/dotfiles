return {
  -- Pin the debug adapters explicitly.
  --
  -- LazyVim's lang.python extra pulls in nvim-dap-python once dap.core is on,
  -- but the adapter it drives - debugpy - is a separate Mason package, and it
  -- was NOT installed here: nvim-dap-python was present with nothing behind it,
  -- so <leader>d on a Python file would have failed at the point of use.
  -- codelldb (C/C++/Rust) was already installed; it is listed so both adapters
  -- are declared in one place rather than one being implicit.
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "debugpy",
        "codelldb",
      })
      return opts
    end,
  },

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

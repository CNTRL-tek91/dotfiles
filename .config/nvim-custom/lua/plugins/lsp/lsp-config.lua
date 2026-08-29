return {
  "neovim/nvim-lspconfig",
  dependencies = { "onsails/lspkind.nvim" },
  config = function()
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    -- Modern Neovim 0.11+ API (vim.lsp.config / vim.lsp.enable). Replaces the
    -- deprecated `require("lspconfig").<server>.setup{}` "framework".
    -- Server definitions (cmd, filetypes, root markers) still come from nvim-lspconfig.

    -- Apply completion capabilities to every server.
    vim.lsp.config("*", { capabilities = capabilities })

    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          format = { enable = false },
        },
      },
    })

    vim.lsp.config("basedpyright", {
      on_attach = function(_, bufnr)
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
      end,
      settings = {
        basedpyright = {
          disableTaggedHints = true,
          disableOrganizeImports = true,
          analysis = {
            typeCheckingMode = "basic",
            ignore = { "*" },
          },
        },
      },
    })

    -- stdpath("config") follows NVIM_APPNAME, so this resolves to this
    -- config's own directory whether it is loaded as ~/.config/nvim or as
    -- ~/.config/nvim-custom. Hardcoding ~/.config/nvim broke the moment
    -- LazyVim took that path over.
    local ruff_config_path = vim.fn.stdpath("config") .. "/tool_configs/ruff.toml"
    vim.lsp.config("ruff", {
      init_options = {
        settings = {
          format = { args = { "--config=" .. ruff_config_path } },
          lint = { args = { "--config=" .. ruff_config_path } },
        },
      },
    })

    vim.lsp.config("html", {})
    vim.lsp.config("bashls", {})

    -- C / C++ (uses the system `clangd`, already installed).
    vim.lsp.config("clangd", {})

    -- JavaScript / TypeScript (needs `typescript-language-server` from Mason; Node is present).
    vim.lsp.config("ts_ls", {})

    -- C# (needs `omnisharp` from Mason AND the .NET SDK installed on the system:
    --   sudo pacman -S dotnet-sdk
    -- Without the .NET SDK this server won't start.)
    vim.lsp.config("omnisharp", {})

    vim.lsp.enable({
      "lua_ls",
      "basedpyright",
      "ruff",
      "html",
      "bashls",
      "clangd",
      "ts_ls",
      "omnisharp",
    })
  end,
}

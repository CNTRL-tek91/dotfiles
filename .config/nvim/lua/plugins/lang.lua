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

  -- The <leader>cv picker was showing a column of "cwd" instead of venv names.
  -- Three separate things were behind that:
  --
  --   1. "cwd" is not a name - it is the *search* that produced the row. The
  --      default picker_columns is {marker, search_icon, search_name,
  --      search_result}, and search_name is padded to 15 columns. Under snacks'
  --      narrow "select" layout that pushes the actual python path off the
  --      right edge, so every row just reads "cwd".
  --   2. The venvs live in ~/.venvs, which none of the plugin's default
  --      searches look at - it knows ~/.virtualenvs, poetry, pyenv, conda and
  --      pipx, but not ~/.venvs. cntrl1-venv only ever appeared because each
  --      project symlinks .venv -> ~/.venvs/cntrl1-venv and the cwd search
  --      follows symlinks (-L).
  --   3. Following those symlinks meant the *same* venv was listed once per
  --      project that links to it, every row labelled "cwd" and distinguished
  --      only by the truncated path.
  {
    "linux-cultist/venv-selector.nvim",
    opts = {
      search = {
        -- Make ~/.venvs a first-class source, so the venvs there are found
        -- from any cwd rather than only via a project's .venv symlink.
        venvs = {
          command = "$FD '/bin/python$' ~/.venvs --full-path --color never -HI -a -E site-packages/",
        },

        -- The three path-relative searches, copied from the plugin's Linux
        -- defaults with -L (follow symlinks) removed. Without it a project's
        -- .venv -> ~/.venvs/... link no longer re-lists a venv the `venvs`
        -- search already offers. A real, non-symlinked in-project venv is
        -- still found; a venv symlinked to somewhere *outside* ~/.venvs is
        -- the case this gives up - add its directory as another search above
        -- if that comes up.
        cwd = {
          command =
          "$FD '/bin/python$' '$CWD' --full-path --color never -HI -a -E /proc -E .git/ -E .wine/ -E .steam/ -E Steam/ -E site-packages/",
        },
        workspace = {
          command = "$FD '/bin/python$' '$WORKSPACE_PATH' --full-path --color never -E /proc -HI -a",
        },
        file = {
          command = "$FD '/bin/python$' '$FILE_DIR' --full-path --color never -E /proc -HI -a",
        },
      },

      options = {
        -- Drop the 15-wide search_name column. The icon in front of each row
        -- already encodes which search found it, and this hands the width
        -- back to the part that identifies the venv.
        picker_columns = { "marker", "search_icon", "search_result" },

        -- Display "<venv name>  <parent dir>" instead of the full path to the
        -- python binary: "cntrl1-venv  ~/.venvs" rather than
        -- "/home/cntrl/.venvs/cntrl1-venv/bin/python". Only the display name
        -- changes - the path that actually gets activated is untouched.
        --
        -- fs_realpath is applied to the venv *directory*, not to the python
        -- path itself: a venv's bin/python is normally a symlink to the system
        -- interpreter, so resolving the file walks straight out of the venv and
        -- reports "usr /". Resolving the directory instead turns a
        -- project's .venv link into the real ~/.venvs/<name> it points at.
        on_telescope_result_callback = function(line)
          local dir = vim.fn.fnamemodify(line, ":h:h")
          dir = vim.uv.fs_realpath(dir) or dir
          local name = vim.fn.fnamemodify(dir, ":t")
          local parent = vim.fn.fnamemodify(dir, ":~:h")
          return string.format("%-22s %s", name, parent)
        end,
      },
    },
  },

}

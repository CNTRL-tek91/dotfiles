# nvim — LazyVim

LazyVim on top of Neovim 0.12. The hand-rolled config this replaced is still in
the repo at [`../nvim-custom`](../nvim-custom/README.md) and still runs — `vc`.

## Layout

| Path | |
|---|---|
| `init.lua` | bootstraps `config.lazy`, untouched from the LazyVim starter |
| `lua/config/` | `options`, `keymaps`, `autocmds` — **only the deltas** from LazyVim's defaults |
| `lua/plugins/` | one file per group; every `.lua` here is auto-imported as a spec |
| `lazyvim.json` | which LazyVim extras are enabled |
| `lazy-lock.json` | pinned plugin commits |
| `tool_configs/ruff.toml` | global ruff settings, carried over from nvim-custom |
| `colors/` | **generated** by lushwal, gitignored |

The `lua/config/` files intentionally do not repeat anything LazyVim already
sets identically — see the comments in each for what was dropped and why.

## Theming

`lua/plugins/colorscheme.lua` wires Neovim into the desktop's wallpaper theming.
**lushwal** builds a colorscheme from pywal's `~/.cache/wal` output at startup,
so the editor matches whatever wallpaper is up, live or static. Colours refresh
on the next launch after a wallpaper change.

**transparent.nvim** is enabled because kitty runs at `background_opacity 0.8` —
without it the editor would be an opaque rectangle on a translucent desktop.

`<leader>uC` picks a different colorscheme, and the choice is remembered across
restarts in `stdpath("data")/last-colorscheme.txt`. Save `lushwal` (or delete
the file) to go back to wallpaper-driven colours.

## Keymaps that changed from nvim-custom

LazyVim's own keymaps are the ones to learn; `<leader>sk` lists everything. The
single-letter maps below were **not** carried over on purpose — `<leader>f`,
`<leader>b`, `<leader>g` and friends are which-key *group* prefixes in LazyVim,
and binding them directly would shadow every command underneath.

| nvim-custom | LazyVim |
|---|---|
| `<leader>f` find files | `<leader>ff` |
| `<leader>gr` live grep | `<leader>sg`, or `<leader>/` |
| `<leader>rf` recent files | `<leader>fr` |
| `<leader>b` buffers | `<leader>,` |
| `<leader>km` keymaps | `<leader>sk` |
| `<leader>n` notifications | `<leader>sn` |
| `<leader>td` todos | `<leader>st` |
| `<leader>th` colorscheme | `<leader>uC` |
| `<leader>xd` / `<leader>xb` diagnostics | `<leader>xx` / `<leader>xX` |
| `<leader>gf` format | `<leader>cf` |
| `<leader>rn` rename | `<leader>cr` \* |
| `<leader>o` outline | `<leader>cs` |
| `<leader>lg` / `<leader>gs` git | `<leader>gg` — **needs the `lazygit` binary, see below** |
| `<leader>gp` preview hunk | `<leader>ghp` \* |
| `<leader>e` focus explorer | `<leader>e` (root) / `<leader>E` (cwd) |
| `<leader>nn` `<leader>nf` … tests | `<leader>tr` `<leader>tt` … |
| `<leader>co` / `<leader>ct` compiler | `<leader>oo` run task, `<leader>ow` task list, `<leader>ot` task action |
| `<leader>mp` markdown preview | `<leader>cp` \* |
| `<leader>rm` render markdown | `<leader>um` |
| `<leader>dv` `<leader>dc` `<leader>df` diffview | `<leader>gdo` `<leader>gdc` `<leader>gdf` |
| `<leader>cc` / `<leader>cs` codesnap | `<leader>cc` / `<leader>cS` |
| `<leader>tr` translate | `<leader>cT` |
| `<C-\>` toggleterm | `<C-/>`, or `<C-\>` (kept) |

\* Buffer-local — only mapped once the relevant buffer attaches (LSP for
`<leader>cr`, a git-tracked file for `<leader>ghp`, a markdown file for
`<leader>cp`), so they will not show in a global keymap dump.

### `<leader>gg` needs lazygit installed

LazyVim only maps `<leader>gg` when the `lazygit` binary exists, and it is not
installed on this machine — nor is it in `system/pkglist-native.txt`. This is
pre-existing, not new: nvim-custom's `lazygit.nvim` plugin and its `<leader>lg`
map needed the same binary and never had it either. But nvim-custom also had
vim-fugitive, which did work, and that is not carried over. So until
`pacman -S lazygit` (and a line in the pkglist), there is no in-editor git
status here — use `<leader>gh*` hunks, `<leader>gd*` diffview, or the shell.

Kept as-is because LazyVim leaves them free: `jk` to leave insert mode, `<C-n>`
explorer toggle, `<A-w>` buffer delete, `<C-\>` terminal. Window navigation
`<C-h/j/k/l>`, resizing `<C-Up/Down/Left/Right>` and buffer cycling
`<S-h>/<S-l>` are LazyVim defaults on the same keys they always were.

## Changing what's installed

`:LazyExtras` toggles extras; it edits `lazyvim.json`. `:Lazy` manages plugins.
Both write files in this directory, so commit afterwards.

Two choices worth knowing about:

- **Explorer.** LazyVim v16 ships none by default. `editor.snacks_explorer` is
  enabled; swap it for `editor.neo-tree` in `lazyvim.json` for a tree closer to
  the old nvim-tree.
- **Picker.** The snacks picker is LazyVim's default. `editor.telescope` brings
  telescope back if the old muscle memory wins.

## Not carried over from nvim-custom

| | Why |
|---|---|
| `compiler.nvim` | hard-requires telescope; `editor.overseer` (its own backend) does the job |
| `none-ls` | conform + nvim-lint cover stylua, shfmt, prettier, hadolint |
| `vim-fugitive` | lazygit on `<leader>gg` — **but see the lazygit note above** |
| `gen.nvim` | needs ollama, not installed |
| `llm.nvim`, `codeium` | already disabled in nvim-custom |
| `luarocks.nvim`, `hererocks` | only existed to build the magick rock; image.nvim uses `magick_cli` |
| `autoclose`, `Comment.nvim`, `nvim-surround` | mini.pairs, ts-comments, mini.surround |
| BufEnter auto-`cd` | fights LazyVim's root detection — see `lua/config/autocmds.lua` |

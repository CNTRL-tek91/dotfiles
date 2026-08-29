# nvim-custom — the pre-LazyVim Neovim config

This is the hand-rolled Neovim config that lived at `.config/nvim` until the
LazyVim migration. It is kept here **working, not archived**: it still runs, and
switching back to it is a one-line change.

It was moved with `git mv`, so `git log --follow <file>` still shows the full
history of everything in here.

## Running it

```sh
vc              # alias in .zshrc  ->  NVIM_APPNAME=nvim-custom nvim
```

`NVIM_APPNAME` redirects *every* Neovim directory at once, so this config gets
its own plugins and state and shares nothing with LazyVim:

| | LazyVim (default) | this config (`NVIM_APPNAME=nvim-custom`) |
|---|---|---|
| config | `~/.config/nvim` | `~/.config/nvim-custom` |
| plugins | `~/.local/share/nvim` | `~/.local/share/nvim-custom` |
| state (shada, undo) | `~/.local/state/nvim` | `~/.local/state/nvim-custom` |
| cache | `~/.cache/nvim` | `~/.cache/nvim-custom` |

Both configs pin their own plugin versions in their own `lazy-lock.json`, so a
`:Lazy update` in one cannot move the other.

## Switching back to it permanently

Point the stow link at this directory instead of the LazyVim one:

```sh
ln -sfn ../.dotfiles/.config/nvim-custom ~/.config/nvim
```

Plain `nvim` then loads this config again. Note it will use the *default* data
dirs (`~/.local/share/nvim`) in that case, not the `-custom` ones — so it does a
one-time plugin install on first launch. To keep using the plugins already
installed here, move them across first:

```sh
mv ~/.local/share/nvim ~/.local/share/nvim-lazyvim   # park LazyVim's
mv ~/.local/share/nvim-custom ~/.local/share/nvim
```

To undo the switch, `stow -d ~/.dotfiles -t ~ --restow .` puts the link back on
`.config/nvim`.

## What's in here

| Path | |
|---|---|
| `init.lua` | entry point; loads the four `core` modules in order |
| `lua/core/` | `options`, `keymaps`, `autocommands`, `lazy` (plugin bootstrap), `colorscheme` |
| `lua/plugins/` | one file per plugin, grouped by category, imported by directory in `core/lazy.lua` |
| `lazy-lock.json` | pinned plugin commits |
| `tool_configs/` | `stylua.toml`, `ruff.toml` — used by none-ls |

Theming came from **lushwal**, which reads pywal's `~/.cache/wal` output, so the
editor followed the wallpaper like everything else on this desktop.
`core/colorscheme.lua` remembers the last theme picked via `<leader>th` in
`~/.local/share/nvim-custom/last-colorscheme.txt` and restores it on launch,
falling back to lushwal and then tokyonight.

## Dead output to be aware of

`wallust.toml` writes `lua/wallust_base16.lua` here on every wallpaper change,
but **nothing in this config ever reads it** — lushwal handles the theming from
pywal's cache instead. It is gitignored. Left in place so this config stays
byte-for-byte what it was; delete the `nvim.template`/`nvim.target` pair from
`.config/wallust/wallust.toml` if you want it gone.

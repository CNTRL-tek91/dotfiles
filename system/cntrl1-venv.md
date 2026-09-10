# cntrl1-venv — shared ML/AI environment

One shared venv at `~/.venvs/cntrl1-venv`, deliberately outside any project
directory. Python 3.14.7, 258 packages, ~7.1 GB.

## Recreating it

```sh
uv venv ~/.venvs/cntrl1-venv
VIRTUAL_ENV=~/.venvs/cntrl1-venv uv pip install -r ~/.dotfiles/system/cntrl1-venv-requirements.txt
```

`cntrl1-venv-requirements.txt` is a full `uv pip freeze`, so it pins transitive
dependencies too - it reproduces this exact environment, not an approximation.

## Using it

```sh
source ~/.venvs/cntrl1-venv/bin/activate
```

Neovim needs no configuration: `lua/util/run.lua` resolves `$VIRTUAL_ENV`
first, so `<leader>or` runs against this venv whenever it is activated, and
basedpyright resolves imports from it the same way.

## Why a venv and not a system-wide install

Arch marks its Python externally managed (PEP 668), so `pip install` outside a
venv is refused outright. 159 pacman packages own files under
`/usr/lib/python3.14/site-packages`; pip writing there is what that rule
prevents. The supported machine-wide route is pacman (`python-numpy`,
`python-pytorch`, ...), but Arch's versions are Arch's choice and much of this
list - transformers, lightning, peft, mlflow - is not packaged at all.

Separate venvs are cheap, so this being shared is a convenience, not a saving:
uv hardlinks package files from its cache, so a second venv with the same
libraries costs almost no extra disk. Measured on this machine: a duplicate
venv reported 7.8 MB of packages while consuming ~400 KB, same inode, link
count 3. That only holds within one filesystem - uv falls back to copying
across a boundary, so keep projects under `~` rather than `/tmp`.

The real cost of sharing is coupling: installing for one project silently
changes the environment every other project sees. For anything that has to be
reproducible later, prefer a project-local `.venv` plus its own frozen
requirements.

## Things that needed deciding

**`cuda` is not a pip package.** torch's PyPI wheels bundle their own CUDA
runtime - `torch 2.14.0+cu130` here - and drive the RTX 2060 (sm_75) with no
system CUDA toolkit installed. The pacman `cuda` package is only needed to
compile CUDA kernels or build C++ against the toolkit.

**Keras needs a backend.** It defaults to TensorFlow, which cannot be installed
from PyPI on Python 3.14 (no cp314 wheels as of 2.21.0). `~/.keras/keras.json`
is tracked in this repo and sets torch. See that commit for detail.

**TensorFlow, if it is ever needed.** Arch's own `python-tensorflow` is built
against system Python 3.14 and would work; the PyPI wheels would need a venv
pinned to 3.13 (`uv venv --python 3.13`).

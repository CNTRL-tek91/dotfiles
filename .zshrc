# Plugin manager
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [ ! -d $ZINIT_HOME ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "$ZINIT_HOME/zinit.zsh"

# Plugins
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-syntax-highlighting
zinit light Aloxaf/fzf-tab
zinit light MichaelAquilina/zsh-auto-notify

# Snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit
zinit cdreplay -q

autoload -U select-word-style
select-word-style bash

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
HISTDUPE=erase

# zsh options
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

# Envs
export EDITOR=nvim
export MANPAGER="$EDITOR +Man!"
export PATH=$HOME/.local/bin:$PATH
export AUTO_NOTIFY_THRESHOLD=20
export AUTO_NOTIFY_TITLE="Hey! '%command' has just finished"
export AUTO_NOTIFY_BODY="It completed in %elapsed seconds"

# Aliases
alias ls='lsd --tree --depth 1 --group-dirs=first'
alias lsr='lsd --recursive --depth 1 --group-dirs=first'
alias v="nvim"
# The pre-LazyVim custom config, kept in the repo under .config/nvim-custom.
# NVIM_APPNAME gives it its own plugin/state dirs (~/.local/share/nvim-custom),
# so the two configs never share plugins and neither can break the other.
alias vc="NVIM_APPNAME=nvim-custom nvim"
alias cat="bat --theme base16"
alias bt="btop"
alias dil="docker images"
alias dcl="docker container ls -a"
alias gc="git clone"
alias upgr="sudo pacman -Syyu"
alias aupgr="paru -Sua"
alias pinst="pip install"
alias plist="pip list"
alias wgup="wg-quick up"
alias wgdown="wg-quick down"
alias awgup="awg-quick up"
alias awgdown="awg-quick down"
alias zshconf="$EDITOR ~/.zshrc && source ~/.zshrc"

# Completion styling
zstyle ':completion:*' matcher-list \
    'm:{[:lower:]}={[:upper:]}' \
    'l:|=* r:|=*' \
    'r:|=*'
zstyle ':completion:*' completer _complete _approximate
zstyle ':completion:*:*:*:*:files' ignored-patterns ''
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd --color=always --icon=always $realpath'

# Functions
# Auto-activate a project venv on entering its directory, and deactivate on
# leaving - but only ever a venv THIS shell activated.
#
# Two bugs this replaces, both of which fired on an ordinary `cd`:
#
#  1. VIRTUAL_ENV is frequently INHERITED rather than activated here. Neovim
#     sets it (venv-selector, and lua/util/run.lua resolves it too), so any
#     terminal opened inside nvim starts with VIRTUAL_ENV already set - but
#     WITHOUT the `deactivate` function, which only exists once bin/activate
#     has been sourced in this shell. The old code called it unconditionally,
#     printing "zsh: command not found: deactivate" after every cd.
#
#  2. The old test compared $PWD against `dirname $VIRTUAL_ENV`, which is wrong
#     whenever the venv lives outside its project. For ~/.venvs/cntrl1-venv the
#     parent is ~/.venvs, so nothing except ~/.venvs/* counted as "inside the
#     venv" and it tried to deactivate in every other directory on the machine.
#     Remembering the directory we activated FROM is what that test wanted.
detect_virtualenv() {
  local parent
  if [[ -z "$VIRTUAL_ENV" ]] ; then
    # Entering a project with its own venv - activate it and remember where.
    if [[ -d ./venv ]] ; then
      _ZSH_VENV_ROOT="$PWD"
      source ./venv/bin/activate
    elif [[ -d ./.venv ]] ; then
      _ZSH_VENV_ROOT="$PWD"
      source ./.venv/bin/activate
    fi
  elif [[ -n "$_ZSH_VENV_ROOT" ]] ; then
    # We activated it, so we may deactivate it - once we are outside that tree.
    # The function check is belt-and-braces: nothing should clear it while
    # _ZSH_VENV_ROOT is still set, but an inherited-then-overwritten env would.
    if [[ "$PWD"/ != "$_ZSH_VENV_ROOT"/* ]] && (( $+functions[deactivate] )) ; then
      deactivate
      unset _ZSH_VENV_ROOT
    fi
  fi
  # VIRTUAL_ENV set with no _ZSH_VENV_ROOT means it was inherited (from nvim,
  # or an explicit `source .../activate`). Leave it alone - it is not ours to
  # undo, and `deactivate` may not even exist.
}

ddac() {
  docker rm -vf $(docker ps -aq)
}

ddai() {
  docker rmi -f $(docker images -aq)
}

traceroute-mapper() {
traceroute=$(traceroute -q1 $* | sed ':a;N;$!ba;s/\n/%0A/g')
  xdg-open "https://stefansundin.github.io/traceroute-mapper/?trace=$traceroute"
}

# Run Python virtualenv detection script
autoload -U add-zsh-hook
add-zsh-hook chpwd detect_virtualenv

# Shell integrations
eval "$(fzf --zsh)"
eval "$(starship init zsh)"
# zoxide must be initialised last (it checks this and warns otherwise)
eval "$(zoxide init zsh --cmd cd)"

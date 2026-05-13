#!/usr/bin/env bash
# Portable dev environment bootstrap.
#
# Installs a curated set of modern CLI tools (bat, fd, fzf, ripgrep, eza,
# zoxide, jq, just, lazygit, delta, dust, httpie, tldr, btop, watchexec, croc,
# trash, yq, gron, glow, mdcat, mprocs, bandwhich, mosh, tmux, uv, gh + gh-dash),
# plus Bun, and writes a ~/.zshrc.utils snippet you can opt into for ergonomic
# aliases and shell integrations (fzf keybindings, zoxide init).
#
# Designed to run on a fresh / work / borrowed Mac without touching your
# existing .zshrc, .gitconfig, or anything identity-related. One-shot — no
# daemons, no auto-sync. Re-run it whenever you want updates.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/zpalin/dev-bootstrap/main/install.sh | bash
#
# Source: https://github.com/zpalin/dev-bootstrap

set -euo pipefail

# ---------- which tools to install ----------
# Curated subset of "modern CLI" tools — useful everywhere, no identity bleed,
# no work-conflict concerns.
FORMULAE=(
  bandwhich         # network usage by process (needs sudo to run)
  bat               # cat with syntax highlighting
  btop              # modern htop with graphs
  croc              # E2E-encrypted file transfer between machines
  fd                # find, but fast and sane
  fzf               # fuzzy finder (also wires Ctrl-R history search)
  gh                # GitHub CLI
  git-delta         # side-by-side git diffs
  glow              # markdown renderer (TUI + per-file)
  gron              # make JSON greppable for grep/awk pipelines
  ripgrep           # rg — fast grep
  eza               # ls replacement
  zoxide            # z — smart cd by frecency
  jq                # JSON processor
  just              # modern make, per-project task runner
  lazygit           # TUI git client
  dust              # disk usage tree
  httpie            # http command, JSON-pretty curl
  mdcat             # markdown cat — inline images in iTerm2
  mprocs            # multi-process TUI for local dev
  tealdeer          # `tldr <cmd>` — practical examples
  trash             # `rm` that goes to macOS Trash (recoverable)
  tree              # classic tree
  uv                # Python package + venv manager
  watchexec         # run a command when files change
  tmux              # terminal multiplexer
  mosh              # SSH that survives reconnects
  yq                # jq for YAML / TOML / XML
)

# `gh` extensions — installed via `gh extension install <repo>` after gh itself
# is in place. Skip if you don't use gh.
GH_EXTENSIONS=(
  dlvhdr/gh-dash    # `gh dash` — TUI dashboard for PRs/issues across repos
)

# ---------- helpers ----------
log() { printf '\n\033[1;36m==>\033[0m %s\n' "$*"; }
ok()  { printf '\033[1;32m✓\033[0m %s\n' "$*"; }

# ---------- brew ----------
if ! command -v brew >/dev/null 2>&1; then
  log "installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Activate brew shellenv for the rest of this script regardless of arch
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ---------- formulae ----------
log "installing ${#FORMULAE[@]} CLI tools via brew"
# brew install is idempotent (skips already-installed) but slow if you list a
# bunch; faster to check first.
missing=()
installed=$(brew list --formula -1)
for f in "${FORMULAE[@]}"; do
  bare="${f##*/}"
  grep -qx "$bare" <<<"$installed" || missing+=("$f")
done
if [ "${#missing[@]}" -eq 0 ]; then
  ok "all tools already installed"
else
  brew install "${missing[@]}"
fi

# ---------- migrate z.sh history into zoxide ----------
# If you previously used the z.sh "frecency" jump tool, its history lives at
# ~/.z. Import it into zoxide on first run so your old jump targets carry over.
# The .imported sentinel makes this idempotent across re-runs.
if [ -f "$HOME/.z" ] && [ ! -f "$HOME/.z.imported-to-zoxide" ] && command -v zoxide >/dev/null; then
  log "migrating ~/.z history into zoxide"
  if zoxide import --from z "$HOME/.z"; then
    mv "$HOME/.z" "$HOME/.z.imported-to-zoxide"
    ok "imported $(wc -l < "$HOME/.z.imported-to-zoxide" | tr -d ' ') entries; backup left at ~/.z.imported-to-zoxide"
  fi
fi

# Surface a heads-up if z.sh sourcing is still in their .zshrc — script
# intentionally doesn't edit user dotfiles.
if grep -q "z/z\.sh\|/z\.sh" "$HOME/.zshrc" 2>/dev/null; then
  log "heads-up: your ~/.zshrc still sources z.sh. Comment out or remove that line so zoxide's \`z\` takes over without conflicts."
fi

# ---------- gh extensions ----------
if command -v gh >/dev/null 2>&1 && [ "${#GH_EXTENSIONS[@]}" -gt 0 ]; then
  log "installing gh extensions"
  installed_exts=$(gh extension list 2>/dev/null || true)
  for ext in "${GH_EXTENSIONS[@]}"; do
    if ! grep -q "$ext" <<<"$installed_exts"; then
      gh extension install "$ext"
    fi
  done
fi

# ---------- bun ----------
if ! command -v bun >/dev/null 2>&1 && [ ! -x "$HOME/.bun/bin/bun" ]; then
  log "installing Bun"
  curl -fsSL https://bun.sh/install | bash
fi

# ---------- zshrc.utils ----------
log "writing ~/.zshrc.utils (you choose whether to source it)"
cat > "$HOME/.zshrc.utils" <<'EOF'
# Portable dev ergonomics — sourced from your .zshrc by adding:
#   [ -f ~/.zshrc.utils ] && source ~/.zshrc.utils
#
# Generated by https://github.com/zpalin/dev-bootstrap

# brew on PATH first — needed if your work .zshrc doesn't already do this
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# bun, if installed
[ -d "$HOME/.bun/bin" ] && export PATH="$HOME/.bun/bin:$PATH"

# zoxide — `z <partial>` jumps to most-used dir matching partial
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# fzf — Ctrl-R fuzzy history, Ctrl-T fuzzy file picker, **<TAB> completions
FZF_PREFIX="$(brew --prefix fzf 2>/dev/null)"
if [ -n "$FZF_PREFIX" ] && [ -d "$FZF_PREFIX/shell" ]; then
  source "$FZF_PREFIX/shell/key-bindings.zsh"
  source "$FZF_PREFIX/shell/completion.zsh"
fi
unset FZF_PREFIX

# direnv hook (only if installed)
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# Modern replacements — comment any you don't want
alias cat='bat --paging=never --style=plain'
alias ls='eza'
alias ll='eza -l --git'
alias la='eza -la --git'
alias tree='eza --tree'

# delta as the git pager (only affects interactive git)
export GIT_PAGER='delta --side-by-side --line-numbers'

# History — zsh defaults are tiny. Set sane sizes + good behavior.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY           # all panes see all history
setopt INC_APPEND_HISTORY      # write history line-by-line, not just on exit
setopt HIST_IGNORE_DUPS        # don't store consecutive duplicates
setopt HIST_IGNORE_SPACE       # don't store commands prefixed with a space
setopt HIST_REDUCE_BLANKS      # collapse whitespace in stored commands
setopt HIST_VERIFY             # !! and friends ask before executing

# Pager / less — colors through pipes, exit if one screenful, no clear, mouse
export PAGER=less
export LESS='-R -F -X --mouse'

# Brew — skip auto-update on every command (you can run `brew update` manually
# when you want), and opt out of analytics
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1

# EDITOR — set a sensible default if nothing else has
: "${EDITOR:=vim}"
: "${VISUAL:=$EDITOR}"
export EDITOR VISUAL

EOF
ok "wrote $HOME/.zshrc.utils"

# ---------- done ----------
cat <<EOF

\033[1;32m✓ Bootstrap complete.\033[0m

To activate the ergonomics, add this single line to your ~/.zshrc:

  [ -f ~/.zshrc.utils ] && source ~/.zshrc.utils

Then open a new shell, or run \`exec zsh\`.

Highlights you now have:
  rg              fast grep
  fd <pattern>    fast find
  bat <file>      cat with syntax highlight
  Ctrl-R          fuzzy shell history (fzf)
  Ctrl-T          fuzzy file picker (fzf)
  z <partial>     smart cd by frecency (zoxide)
  lazygit         TUI git client
  just            modern make
  http GET ...    JSON-pretty curl alternative
  tldr <cmd>      practical examples for any CLI
  btop            modern htop
  watchexec       rerun commands on file change
  croc send X     E2E-encrypted file transfer to another machine
  trash <file>    rm that goes to Trash (recoverable)
  gh dash         TUI dashboard for your GitHub PRs/issues

Re-run this script whenever you want updates. It's idempotent.
EOF

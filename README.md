# dev-bootstrap

A self-contained, idempotent bootstrap for a curated set of modern CLI tools on a Mac. Designed to install on a fresh machine — including work/borrowed laptops — without touching your existing `.zshrc`, `.gitconfig`, or other personal-identity dotfiles.

## Run it

```bash
curl -fsSL https://raw.githubusercontent.com/zpalin/dev-bootstrap/main/install.sh | bash
```

That's it.

## What it does

1. Installs **Homebrew** if missing
2. Installs **Bun** if missing
3. Installs these brew formulae (idempotent — skips if already present):
   `bat · fd · fzf · git-delta · ripgrep · eza · zoxide · jq · just · lazygit · dust · httpie · tree · uv · tmux · mosh`
4. Writes `~/.zshrc.utils` containing fzf keybindings, zoxide init, and ergonomic aliases (`cat=bat`, `ls=eza`, etc.)

## How to activate the ergonomics

Add ONE line to your `~/.zshrc`:

```bash
[ -f ~/.zshrc.utils ] && source ~/.zshrc.utils
```

Then open a new shell.

## What it explicitly does NOT do

- No daemons, no auto-sync, no background processes
- No GitHub auth required (no `git push`, no repo cloning)
- No edits to your existing `.zshrc`, `.gitconfig`, or anything personal
- No identity bleed (no email, name, or hostname configuration)

Re-run anytime to pick up updates. It's idempotent — already-installed packages are skipped.

## Customizing

Don't like `alias cat=bat`? Edit `~/.zshrc.utils` after install and remove the lines you don't want. Re-running the script will overwrite your edits, so consider it an "initial template" and tune to taste.

## Source

This script lives in `install.sh` in this repo. It's deliberately one file, pure bash, no dependencies. Read it before piping to bash if you don't trust me — it's 100 lines and obvious.

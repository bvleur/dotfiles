#!/bin/bash
set -euo pipefail

# Bootstrap script for bvleur/dotfiles
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/bvleur/dotfiles/main/install.sh)

# --- Find Homebrew (not installed here: it needs admin rights, or a self-service portal on a managed Mac) ---
if ! command -v brew >/dev/null 2>&1; then
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$b" ]; then eval "$("$b" shellenv)"; break; fi
  done
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Install it first (https://brew.sh, or your self-service portal), then run this script again." >&2
  exit 1
fi
echo "==> Homebrew found: $(command -v brew)"

# --- Install chezmoi via Homebrew ---
if ! command -v chezmoi >/dev/null 2>&1; then
  echo "==> Installing chezmoi via Homebrew..."
  brew install chezmoi
else
  echo "==> chezmoi already installed, skipping."
fi

# --- Initialize and apply dotfiles ---
# chezmoi asks for the machine type itself (see .chezmoi.toml.tmpl).
echo "==> Running chezmoi init --apply..."
chezmoi init --apply https://github.com/bvleur/dotfiles.git

echo ""
echo "Done. Restart your shell or open a new terminal to load the new configuration."

#!/bin/bash
set -euo pipefail

# Bootstrap script for bvleur/dotfiles
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/bvleur/dotfiles/main/install.sh)

# --- Install Homebrew if missing ---
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Homebrew not found, installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for the rest of this script
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "==> Homebrew already installed, skipping."
  eval "$(brew shellenv)"
fi

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

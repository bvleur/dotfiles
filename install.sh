#!/bin/bash
set -euo pipefail

# Bootstrap script for bvleur/dotfiles
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/bvleur/dotfiles/main/install.sh)

# --- Ask for machine purpose ---
echo ""
echo "What kind of machine is this?"
echo "  1) home  — personal laptop (general tools only)"
echo "  2) bol   — work laptop (includes bol-specific tools)"
echo ""
while true; do
  read -rp "Choose [1/2]: " choice
  case "$choice" in
    1|home) PURPOSE="home"; break ;;
    2|bol)  PURPOSE="bol";  break ;;
    *) echo "Please enter 1 or 2." ;;
  esac
done
echo "→ purpose = \"$PURPOSE\""
echo ""

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

# --- Write chezmoi.toml before init/apply ---
CHEZMOI_CONFIG_DIR="$HOME/.config/chezmoi"
mkdir -p "$CHEZMOI_CONFIG_DIR"
cat > "$CHEZMOI_CONFIG_DIR/chezmoi.toml" <<EOF
[data]
  purpose = "$PURPOSE"
EOF
echo "==> Wrote $CHEZMOI_CONFIG_DIR/chezmoi.toml"

# --- Initialize and apply dotfiles ---
echo "==> Running chezmoi init..."
chezmoi init https://github.com/bvleur/dotfiles.git

echo "==> Running chezmoi apply..."
chezmoi apply

echo ""
echo "Done. Restart your shell or open a new terminal to load the new configuration."

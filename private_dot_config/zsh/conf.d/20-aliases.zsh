# 20-aliases.zsh — aliases

# open the chezmoi source repo in zed
alias dots='zed "$(chezmoi source-path)"'

# --- modern replacements (only active when the tool exists) ---
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'
# don't override grep (rg and grep differ in flags / exit-code semantics); provide rgg separately
command -v rg  >/dev/null 2>&1 && alias rgg='rg'
# eza replaces ls / tree
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --git'
  alias ll='eza -l --icons --git'
  alias la='eza -la --icons --git'
  alias tree='eza --tree --icons'
fi

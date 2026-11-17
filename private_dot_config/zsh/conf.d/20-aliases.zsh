# 20-aliases.zsh — aliases
#
# Convention (read by `help`, 70-help.zsh): a `#: short description` line directly above an alias or function.

#: open the chezmoi source repo in Zed
alias dots='zed "$(chezmoi source-path)"'

# --- modern replacements (only active when the tool exists) ---
#: cat with syntax highlighting (bat), no pager
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'
# don't override grep (rg and grep differ in flags / exit-code semantics); provide rgg separately
#: ripgrep, next to the untouched grep
command -v rg  >/dev/null 2>&1 && alias rgg='rg'
# eza replaces ls / tree
if command -v eza >/dev/null 2>&1; then
  #: ls with icons and git status (eza)
  alias ls='eza --icons --git'
  #: long listing with icons and git status
  alias ll='eza -l --icons --git'
  #: long listing including hidden files
  alias la='eza -la --icons --git'
  #: directory tree with icons
  alias tree='eza --tree --icons'
fi

#: watch, via viddy (history, pause, diff highlighting)
command -v viddy >/dev/null 2>&1 && alias watch='viddy'

# --- git (the rest goes through lazygit) ---
#: git status
alias gs='git status'

#: git pull
alias gl='git pull'

#: git push
alias gp='git push'

# an alias appends its arguments, so `gcam "message"` runs `git commit --all --message "message"`
#: commit all tracked changes, message as argument: gcam "message"
alias gcam='git commit --all --message'

#: lazygit (git TUI)
command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'

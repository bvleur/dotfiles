# 20-aliases.zsh — aliases
#
# Convention (read by `help`, 70-help.zsh): a `#: short description` line directly above an alias or function.

#: [system config] open the chezmoi source repo in Zed
alias dots='zed "$(chezmoi source-path)"'

# `cu` (chezmoi update) is a function in 40-reload.zsh: it reloads this shell when the zsh config changed.

# --- modern replacements (only active when the tool exists) ---
#: [files, more] cat with syntax highlighting (bat), no pager
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'
# eza replaces ls / tree
if command -v eza >/dev/null 2>&1; then
  #: [files, more] ls with icons and git status (eza)
  alias ls='eza --icons --git'
  #: [files] long listing with icons and git status
  alias ll='eza -l --icons --git'
  #: [files] long listing including hidden files
  alias la='eza -la --icons --git'
  #: [files] directory tree with icons
  alias tree='eza --tree --icons'
fi

#: [more] watch, via viddy (history, pause, diff highlighting)
command -v viddy >/dev/null 2>&1 && alias watch='viddy'

# Homebrew installs the gdu formula as `gdu-go` (the name `gdu` belongs to GNU du from coreutils, which is not installed here).
#: [files] interactive disk usage analyzer (gdu), like DaisyDisk in the terminal
command -v gdu-go >/dev/null 2>&1 && alias gdu='gdu-go'

# --- git (the rest goes through lazygit) ---
#: [git] git status
alias gs='git status'

#: [git] git pull
alias gl='git pull'

#: [git] git push
alias gp='git push'

# an alias appends its arguments, so `gcam "message"` runs `git commit --all --message "message"`
#: [git] commit all tracked changes, message as argument: gcam "message"
alias gcam='git commit --all --message'

#: [git] lazygit (git TUI)
command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'

# zsh expands aliases before completing, so `mr <Tab>` uses mise's `mise run` completion (no compdef needed)
#: [dev] mise run: run a mise task (mr <task>)
command -v mise >/dev/null 2>&1 && alias mr='mise run'

# --- command fixes ---
# pay-respects (offline, rule-based; `ccd` fixes with Claude): `f` re-runs the previous failed command, corrected.
# AI suggestions are disabled (_PR_AI_DISABLE in 00-env.zsh); --nocnf skips its command_not_found handler.
#: [system config] fix the previous failed command (pay-respects, offline, no AI)
command -v pay-respects >/dev/null 2>&1 && eval "$(pay-respects zsh --alias f --nocnf)"

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

# --- git (a small subset, same names as the Oh My Zsh git plugin) ---
#: git
alias g='git'
#: git status
alias gst='git status'
#: git add --all
alias gaa='git add --all'
#: git commit --message
alias gcmsg='git commit --message'
#: git commit --all --message
alias gcam='git commit --all --message'
#: git diff
alias gd='git diff'
#: git switch
alias gsw='git switch'
#: git branch
alias gb='git branch'
#: git pull
alias gl='git pull'
#: git pull --rebase
alias gpr='git pull --rebase'
#: git push
alias gp='git push'
#: git push --force-with-lease (safe force push)
alias gpf='git push --force-with-lease'
#: git push and set upstream to origin/<current branch>
alias gpsup='git push --set-upstream origin HEAD'
#: git log, one line per commit with graph
alias glog='git log --oneline --decorate --graph'

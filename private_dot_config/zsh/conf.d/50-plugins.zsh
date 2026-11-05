fpath+=("$(brew --prefix)/share/zsh/site-functions")

source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
antidote load

eval "$(zoxide init zsh)"
eval "$(mise activate zsh)"

#: interactive zoxide picker (fzf), then cd; same as Z in yazi
alias Z='zi'

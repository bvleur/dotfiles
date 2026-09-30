fpath+=("$(brew --prefix)/share/zsh/site-functions")

source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
antidote load

eval "$(zoxide init zsh)"

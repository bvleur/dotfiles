fpath+=("$HOMEBREW_PREFIX/share/zsh/site-functions")

source "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh"
antidote load

eval "$(zoxide init zsh)"
eval "$(mise activate zsh)"

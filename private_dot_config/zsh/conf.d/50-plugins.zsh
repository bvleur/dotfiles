fpath+=("$HOMEBREW_PREFIX/share/zsh/site-functions")

source "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh"
antidote load

eval "$(zoxide init zsh)"
eval "$(mise activate zsh)"
# mise completion (tasks with descriptions for `mise run <Tab>`); needs the `usage` CLI (Brewfile).
# After antidote on purpose: the zephyr completion plugin has run compinit by now, and the script registers itself with compdef.
(( $+commands[usage] )) && eval "$(mise completion zsh)"

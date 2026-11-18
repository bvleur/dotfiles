# 40-reload.zsh — reload the zsh config in every open terminal tab
#
# `reload-all-zsh` sends SIGUSR1 to all zsh processes of this user. Each interactive shell only sets a flag and
# restarts itself (`exec zsh -l`, a clean login shell, unlike `source ~/.zshrc`) at its next prompt, so nothing
# that runs in the foreground (vim, ssh, ...) is interrupted. A tab that is idle at the prompt needs one Enter.
# Shells that were started before this fragment existed don't have the trap yet: restart those once by hand.

typeset -g _zsh_reload_pending=0
trap '_zsh_reload_pending=1' USR1
_zsh_reload_check() { (( _zsh_reload_pending )) && exec zsh -l }
precmd_functions+=(_zsh_reload_check)

# no popular tool or builtin uses this name
#: [system config] restart every open zsh (all terminal tabs) to pick up config changes at the next prompt
alias reload-all-zsh='pkill -USR1 -x zsh'

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

# `cu` = chezmoi update, plus a reload of *this* shell when the zsh config (incl. the pinned plugins, e.g. ccd)
# changed. The run_onchange script only signals shells at their next prompt; doing the exec here makes the
# current shell deterministic instead of depending on signal timing. Other tabs were signalled by that script.
# note: shadows /usr/bin/cu (macOS's old UUCP serial "call up" tool); `command cu` still reaches it
_zsh_config_fingerprint() {
  cat "${ZDOTDIR:-$HOME/.config/zsh}"/conf.d/*(N.) "${ZDOTDIR:-$HOME/.config/zsh}"/.z*(N.) "$HOME/.zshenv"(N.) 2>/dev/null | cksum
}
#: [system config] chezmoi update (pull the dotfiles repo and apply); reloads this shell if the zsh config changed
cu() {
  local before after
  before=$(_zsh_config_fingerprint)
  chezmoi update "$@" || return
  after=$(_zsh_config_fingerprint)
  [[ $before == $after ]] && return 0
  print -P "%F{yellow}zsh config changed (plugins such as ccd included): reloading this shell.%f"
  print "Other open tabs reload at their next prompt (or run: reload-all-zsh)."
  exec zsh -l
}

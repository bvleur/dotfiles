# 35-drift-ui.zsh — shared output helpers for the drift commands (36-brewfile, 37-chezmoi-drift, 38-vicinae-drift)
#
# Colour only when stdout is a terminal and NO_COLOR is not set, so piping the output to a file stays plain.
# Every finding is followed by a "→" line with the command(s) that resolve it.

# Each drift command starts with `local _DRIFT_TTY; _drift_tty`: the terminal check must happen there, because
# inside $(_drift_c …) stdout is always a pipe.
_drift_tty() { [[ -t 1 && -z ${NO_COLOR-} ]] && _DRIFT_TTY=1 || _DRIFT_TTY=0; }

# echo the escape sequence for a colour name, or nothing when colour is off
_drift_c() {
  (( ${_DRIFT_TTY:-0} )) || return 0
  case $1 in
    reset)  print -n -- $'\e[0m' ;;
    bold)   print -n -- $'\e[1m' ;;
    dim)    print -n -- $'\e[2m' ;;
    red)    print -n -- $'\e[31m' ;;
    green)  print -n -- $'\e[32m' ;;
    yellow) print -n -- $'\e[33m' ;;
    blue)   print -n -- $'\e[34m' ;;
    cyan)   print -n -- $'\e[36m' ;;
  esac
}

# ── Section title ──
_drift_header() { print -r -- "$(_drift_c bold)$(_drift_c blue)── $* ──$(_drift_c reset)"; }

# ✓ nothing to do
_drift_ok() { print -r -- "  $(_drift_c green)✓ $*$(_drift_c reset)"; }

# ✗ a problem with the check itself
_drift_err() { print -u2 -r -- "$(_drift_c red)✗ $*$(_drift_c reset)"; }

# a finding; first argument is its kind: + (only here), - (only in repo), ~ (differs), ! (attention)
_drift_item() {
  local kind=$1; shift
  local colour
  case $kind in
    +) colour=green ;;
    -) colour=red ;;
    '~') colour=yellow ;;
    *) colour=yellow ;;
  esac
  print -r -- "  $(_drift_c $colour)$kind$(_drift_c reset) $*"
  _DRIFT_FOUND+=1
  return 0
}

# findings counter, read by chezmoi-drift for its closing summary
typeset -gi _DRIFT_FOUND=0

# → the command that fixes it (cyan, so it stands out and can be copied); an optional "# why" goes dim behind it
_drift_fix() {
  local cmd=$1 why=${2-}
  print -r -- "    $(_drift_c cyan)→ $cmd$(_drift_c reset)${why:+  $(_drift_c dim)# $why$(_drift_c reset)}"
}

# → how to commit changes in the dotfiles repo; every command that suggests a commit uses this, so the tip reads
#   the same everywhere. Usage: _drift_fix_commit [message [path …]]
#   message  pre-filled commit message (default "…", to fill in yourself)
#   path     stage only these, relative to the source dir (default: everything, git add -A)
_drift_fix_commit() {
  local msg=${1:-…}; (( $# )) && shift
  local what="commit them" add="-A"
  if (( $# )); then
    add="-- ${(j: :)${(q-)@}}"
    what="commit it"
  fi
  _drift_fix "chezmoi git -- add $add && chezmoi git -- commit -m \"$msg\"" "$what"
  _drift_fix 'lazygit -p "$(chezmoi source-path)"' "or review and commit in lazygit"
}

# plain explanatory line
_drift_note() { print -r -- "  $(_drift_c dim)$*$(_drift_c reset)"; }

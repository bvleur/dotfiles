#: mkdir -p a directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

#: yazi file manager that cd's to the last directory on exit
y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

#: view files with the best viewer per type (md: glow, docx: doxx, dirs: eza), bat as fallback
v() {
  emulate -L zsh
  (( $# )) || { print -u2 "usage: v <file>..."; return 1 }
  local f rc=0
  for f in "$@"; do
    if [[ -d $f ]]; then
      if (( $+commands[eza] )); then command eza -l --icons --git -- "$f"; else command ls -l -- "$f"; fi
    elif [[ $f == (#i)*.(md|markdown) ]] && (( $+commands[glow] )); then
      command glow -p -s dark -- "$f"      # same renderer as the yazi .md preview
    elif [[ $f == (#i)*.docx ]] && (( $+commands[doxx] )); then
      command doxx "$f"                    # same viewer as the yazi .docx preview
    elif (( $+commands[bat] )); then
      command bat -- "$f"
    else
      command ${PAGER:-less} -- "$f"
    fi || rc=1
  done
  return $rc
}

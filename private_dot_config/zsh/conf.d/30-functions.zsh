#: [files] mkdir -p a directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

#: [files] yazi file manager that cd's to the last directory on exit
y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

#: [files] view files with the best viewer per type (see `v --help`), bat as fallback
v() {
  emulate -L zsh
  if [[ $1 == (-h|--help) ]]; then
    # Keep this table in sync with the dispatch below. Cyan = file type, green = viewer, dim = notes.
    print -P '%BUsage:%b v <file|dir>...\n\nPicks the best installed viewer per file type:\n'
    local -a rows=(
      'directories|ls|(your ls alias, long format)'
      '.md .markdown|glow|(paged with less)'
      '.docx|doxx|'
      '.json|jless|'
      '.csv .tsv|csvlens|(delimiter autodetected)'
      'binary files|hexyl|(paged with less)'
      'everything else|bat|(falls back to $PAGER / less)'
    )
    local row
    for row in $rows; do
      local -a c=("${(@s:|:)row}")
      print -P "  %F{cyan}${(r:17:)c[1]}%f %F{green}${(r:8:)c[2]}%f %F{8}${c[3]}%f"
    done
    print -P '\n%F{8}A viewer that is not installed is skipped; the next match wins.%f'
    return 0
  fi
  (( $# )) || { print -u2 "usage: v <file>... (see v --help)"; return 1 }
  local f lf rc=0
  for f in "$@"; do
    lf=${f:l}   # lowercase copy: case-insensitive extension match without needing extendedglob (`emulate -L zsh` turns it off)
    if [[ -d $f ]]; then
      # eval so the user's ls alias/function is looked up at call time (aliases are expanded at parse time otherwise)
      eval "ls -l -- ${(q)f}"
    elif [[ $lf == *.(md|markdown) ]] && (( $+commands[glow] )); then
      # Same invocation as the yazi piper previewer (forced colour, explicit width, dark style). glow's built-in
      # pager (-p) draws tables differently, so page the output with less instead.
      CLICOLOR_FORCE=1 command glow -w=${COLUMNS:-80} -s=dark "$f" | command less -R
    elif [[ $lf == *.docx ]] && (( $+commands[doxx] )); then
      command doxx "$f"                    # same viewer as the yazi .docx preview
    elif [[ $lf == *.json ]] && (( $+commands[jless] )); then
      command jless -- "$f"
    elif [[ $lf == *.(csv|tsv) ]] && (( $+commands[csvlens] )); then
      command csvlens -- "$f"            # csvlens autodetects the delimiter (default since v0.14.0), also for .tsv
    elif [[ -f $f ]] && (( $+commands[hexyl] )) && [[ $(command file --brief --mime-encoding -- "$f") == binary ]]; then
      command hexyl -- "$f" | command less -R
    elif (( $+commands[bat] )); then
      command bat -- "$f"
    else
      command ${PAGER:-less} -- "$f"
    fi || rc=1
  done
  return $rc
}

#: [files] mkdir -p a directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

#: [files] cd into the shallowest subdirectory with this name, skipping node_modules, .git, build caches etc. (bfs): cdn <name>
cdn() {
  emulate -L zsh
  (( $# == 1 )) || { print -u2 "usage: cdn <dirname>"; return 1 }
  (( $+commands[bfs] )) || { print -u2 "cdn: bfs not installed (brew install bfs)"; return 1 }
  # bfs searches breadth-first, so the first hit is the least nested one and -quit stops right there.
  # Noise directories are pruned (-exclude), except one that was asked for by name (`cdn build` still works).
  local -a noise=(node_modules .git .hg .svn vendor target build dist out .next .nuxt .cache .venv venv __pycache__ .gradle .idea .terraform Pods DerivedData)
  noise=(${noise:#$1})
  local -a prune=(-name ${noise[1]})
  local n; for n in ${noise[2,-1]}; do prune+=(-o -name $n); done
  local dir; dir=$(command bfs . -exclude \( $prune \) -type d -name "$1" -print -quit 2>/dev/null)
  [[ -n $dir ]] || { print -u2 "cdn: no directory named '$1' below $PWD"; return 1 }
  builtin cd -- "$dir"
}

#: [files] yazi file manager that cd's to the last directory on exit
y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

#: [files] view files with the best viewer per type (md: glow, docx: doxx, json: jless, csv: csvlens, binary: hexyl, dirs: eza), bat as fallback
v() {
  emulate -L zsh
  (( $# )) || { print -u2 "usage: v <file>..."; return 1 }
  local f lf rc=0
  for f in "$@"; do
    lf=${f:l}   # lowercase copy: case-insensitive extension match without needing extendedglob (`emulate -L zsh` turns it off)
    if [[ -d $f ]]; then
      if (( $+commands[eza] )); then command eza -l --icons --git -- "$f"; else command ls -l -- "$f"; fi
    elif [[ $lf == *.(md|markdown) ]] && (( $+commands[glow] )); then
      # Same invocation as the yazi piper previewer (forced colour, explicit width, dark style). glow's built-in
      # pager (-p) draws tables differently, so page the output with less instead.
      CLICOLOR_FORCE=1 command glow -w=${COLUMNS:-80} -s=dark "$f" | command less -R
    elif [[ $lf == *.docx ]] && (( $+commands[doxx] )); then
      command doxx "$f"                    # same viewer as the yazi .docx preview
    elif [[ $lf == *.json ]] && (( $+commands[jless] )); then
      command jless -- "$f"
    elif [[ $lf == *.(csv|tsv) ]] && (( $+commands[csvlens] )); then
      if [[ $lf == *.tsv ]]; then command csvlens -d '\t' -- "$f"; else command csvlens -- "$f"; fi
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

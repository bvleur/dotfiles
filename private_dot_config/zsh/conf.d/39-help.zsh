# 39-help.zsh — `help`: list the custom aliases and functions with a short description
#
# Descriptions live next to the definitions: put a `#: description` line directly above an alias or function
# in any conf.d/*.zsh file and it shows up here automatically. Names starting with _ (helpers) are skipped.
# Entries that aren't active in this shell (e.g. an alias whose tool isn't installed) are shown dimmed.

#: list my custom aliases and functions with a description (help <text> filters)
help() {
  emulate -L zsh
  local _DRIFT_TTY; _drift_tty
  local dir=${ZDOTDIR:-$HOME/.config/zsh}/conf.d
  local -a files; files=($dir/*.zsh(N))
  (( ${#files} )) || { print -u2 "help: no config fragments in $dir"; return 1 }

  local kind name desc active want=${1-} shown=0 last=
  local -a rows
  rows=("${(@f)$(awk '
    /^[[:space:]]*#:/ { d=$0; sub(/^[[:space:]]*#:[[:space:]]*/, "", d); next }
    {
      n=""; t=""
      if      (match($0, /^[[:space:]]*alias[[:space:]]+[^=[:space:]]+=/))      { t="alias"; n=$0; sub(/^[[:space:]]*alias[[:space:]]+/, "", n); sub(/=.*/, "", n) }
      else if (match($0, /^[[:space:]]*(function[[:space:]]+)?[A-Za-z0-9_.-]+[[:space:]]*\(\)/)) { t="function"; n=$0; sub(/^[[:space:]]*(function[[:space:]]+)?/, "", n); sub(/[[:space:]]*\(\).*/, "", n) }
      if (t != "" && d != "" && n !~ /^_/) printf "%s\t%s\t%s\n", t, n, d
      d=""
    }' $files)}")

  for kind in alias function; do
    last=
    for row in $rows; do
      [[ ${row%%$'\t'*} == $kind ]] || continue
      name=${${row#*$'\t'}%%$'\t'*} desc=${row##*$'\t'}
      [[ -n $want && ${name}${desc} != *${~${(b)want}}* ]] && continue
      if [[ $last != $kind ]]; then
        (( shown )) && print ""
        _drift_header ${${kind/alias/Aliases}/function/Functions}
        last=$kind
      fi
      if { [[ $kind == alias ]] && (( ${+aliases[$name]} )) } || { [[ $kind == function ]] && (( ${+functions[$name]} )) }; then
        print -r -- "  $(_drift_c cyan)${(r:24:)name}$(_drift_c reset) $desc"
      else
        print -r -- "  $(_drift_c dim)${(r:24:)name} $desc (not active)$(_drift_c reset)"
      fi
      shown=1
    done
  done
  (( shown )) || print -r -- "nothing found${want:+ for '$want'}"
  _drift_note ""
  _drift_note "Add your own: a '#: description' line above an alias or function in $dir/*.zsh"
}

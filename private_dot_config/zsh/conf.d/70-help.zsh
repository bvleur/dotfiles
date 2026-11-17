# 70-help.zsh — `help`: my custom aliases and functions with a short description, grouped by category
#
# Descriptions live next to the definitions: put a `#: [category] description` line directly above an alias or
# function in any conf.d/*.zsh file and it shows up here automatically. `#: [category, more] …` marks something
# I rarely type: hidden by default, shown with `help --all` and when searching. No category: "other".
# Plugins can take part too: a file in the HELP_SOURCES array (declared in 00-env.zsh; a plugin adds itself,
# e.g. claude-cmd-deluxe) is read the same way. HELP_CATEGORIES sets the order of the categories; others follow
# alphabetically, "other" last.
#
# Rule: a name without a leading _ is a command for me and needs a `#:` line; a name starting with _ is an
# internal helper and is never listed. `help --check` lists public names that lack a `#:` line (exit 1), and
# plain `help` ends with a warning when there are any, so a new alias or function can't silently stay out.
# Loaded after the plugins (50) on purpose: zephyr's utility plugin does `alias help=run-help`, which would
# otherwise win over this function.
unalias help 2>/dev/null

(( ${+HELP_CATEGORIES} )) || typeset -ga HELP_CATEGORIES=('system config' files git ccd)

# Entries that aren't active in this shell (e.g. an alias whose tool isn't installed) are shown dimmed.

#: [more] my aliases and functions by category; help --all also shows rarely used ones, help <text> searches all
help() {
  emulate -L zsh
  local _DRIFT_TTY; _drift_tty
  local dir=${ZDOTDIR:-$HOME/.config/zsh}/conf.d
  local -a files; files=($dir/*.zsh(N) ${^HELP_SOURCES}(N))
  (( ${#files} )) || { print -u2 "help: no config fragments in $dir"; return 1 }

  local all=0 check=0 want= arg
  for arg in "$@"; do
    case $arg in
      -a|--all) all=1 ;;
      --check)  check=1 ;;
      -h)       print -r -- "usage: help [--all] [text] | help --check"; return 0 ;;
      *)        want+=${want:+ }$arg ;;
    esac
  done
  [[ -n $want ]] && all=1   # searching looks through everything

  # one row per entry: kind \t name \t category \t more(0/1) \t description; or missing \t name \t file
  local -a rows
  rows=("${(@f)$(awk '
    /^[[:space:]]*#:/ { d=$0; sub(/^[[:space:]]*#:[[:space:]]*/, "", d); next }
    /^[[:space:]]*#/  { d=""; next }
    {
      n=""; t=""
      # also `cond && alias x=…` (aliases that only exist when their tool is installed)
      if (match($0, /(^[[:space:]]*|&&[[:space:]]*|;[[:space:]]*)alias[[:space:]]+[^=[:space:]]+=/)) {
        t="alias"; n=substr($0, RSTART, RLENGTH); sub(/.*alias[[:space:]]+/, "", n); sub(/=$/, "", n)
      } else if (match($0, /^[[:space:]]*(function[[:space:]]+)?[A-Za-z0-9_.-]+[[:space:]]*\(\)/)) {
        t="function"; n=$0; sub(/^[[:space:]]*(function[[:space:]]+)?/, "", n); sub(/[[:space:]]*\(\).*/, "", n)
      }
      if (t != "" && n !~ /^_/) {
        if (d == "") printf "missing\t%s\t%s\n", n, FILENAME
        else {
          c="other"; m=0
          if (substr(d, 1, 1) == "[" && (e = index(d, "]")) > 0) {
            tag=substr(d, 2, e - 2); d=substr(d, e + 1); sub(/^[[:space:]]+/, "", d)
            k=split(tag, parts, /[[:space:]]*,[[:space:]]*/)
            for (i = 1; i <= k; i++) {
              p=parts[i]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", p)
              if (p == "more") m=1; else if (p != "") c=p
            }
          }
          printf "%s\t%s\t%s\t%d\t%s\n", t, n, c, m, d
        }
      }
      d=""
    }' $files)}")
  rows=(${rows:#})

  local -a missing=(${(M)rows:#missing$'\t'*})
  rows=(${rows:#missing$'\t'*})
  local row

  if (( check )); then
    if (( ${#missing} )); then
      _drift_header "Without a '#:' description"
      for row in $missing; do
        print -r -- "  $(_drift_c yellow)${(r:24:)${${row#*$'\t'}%%$'\t'*}}$(_drift_c reset) ${${row##*$'\t'}:t}"
      done
      _drift_note "add a '#: [category] …' line above each, or give internal helpers a leading _ in the name"
      return 1
    fi
    _drift_ok "every alias and function has a description"
    return 0
  fi

  # category order: HELP_CATEGORIES, then the others alphabetically, then "other"
  local -a f cats extra
  for row in $rows; do
    f=("${(@ps:\t:)row}")
    (( ${HELP_CATEGORIES[(Ie)${f[3]}]} || ${extra[(Ie)${f[3]}]} )) || [[ ${f[3]} == other ]] || extra+=(${f[3]})
  done
  cats=($HELP_CATEGORIES ${(io)extra} other)

  local cat kind name desc shown=0 hidden=0 first
  for cat in $cats; do
    first=1
    for row in $rows; do
      f=("${(@ps:\t:)row}")
      [[ ${f[3]} == $cat ]] || continue
      kind=${f[1]} name=${f[2]} desc=${f[5]}
      [[ -n $want && ${name}${desc} != *${~${(b)want}}* ]] && continue
      if (( f[4] && ! all )); then
        (( hidden++ ))
        continue
      fi
      if (( first )); then
        (( shown )) && print ""
        _drift_header $cat
        first=0
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
  if (( ${#missing} )); then
    print ""
    print -r -- "$(_drift_c yellow)! ${#missing} without a description (not listed): help --check$(_drift_c reset)"
  fi
  _drift_note ""
  (( hidden )) && _drift_note "$hidden rarely used ones hidden: help --all"
  _drift_note "Add your own: a '#: [category] description' line above an alias or function in $dir/*.zsh"
}

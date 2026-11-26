#: [files] mkdir -p a directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

#: [files] cd into the shallowest subdirectory with this name, skipping node_modules, .git, build caches etc. (bfs): cdn <name>
cdn() {
  emulate -L zsh
  (( $# == 1 )) || { print -u2 "usage: cdn <dirname>"; return 1 }
  (( $+commands[bfs] )) || { print -u2 "cdn: bfs not installed (brew install bfs)"; return 1 }
  # -status draws a "currently searching <path>" line on stderr (only on a terminal), so stderr must not be silenced.
  # bfs searches breadth-first, so the first hit is the least nested one and -quit stops right there.
  # Noise directories are pruned (-exclude), except one that was asked for by name (`cdn build` still works).
  local -a noise=(node_modules .git .hg .svn vendor target build dist out .next .nuxt .cache .venv venv __pycache__ .gradle .idea .terraform Pods DerivedData)
  noise=(${noise:#$1})
  local -a prune=(-name ${noise[1]})
  local n; for n in ${noise[2,-1]}; do prune+=(-o -name $n); done
  local dir; dir=$(command bfs -status . -exclude \( $prune \) -type d -name "$1" -print -quit)
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

#: [system config, more] store a UniFi WireGuard client .conf in 1Password for the chezmoi-managed VPN config: wg-to-1password [-m machine] <file.conf> [home-subnet]
wg-to-1password() {
  emulate -L zsh
  # Fills the item that private_dot_config/private_wireguard/private_home.conf.tmpl reads: shared fields plus one
  # section per machine. The section is this machine's chezmoi `purpose` unless -m names another one, so a .conf
  # for the other laptop can be stored from here: wg-to-1password -m bol <file.conf>.
  # The first run creates the item and needs the home subnet (the AllowedIPs to route).
  # Nothing that is already in 1Password is replaced without showing what changes and asking first
  # (-f skips the question; without a terminal and without -f it refuses).
  # The account is named on every op call, so a machine with a work account next to it never asks or picks wrong.
  local account=vleur.1password.com vault=Private item="WireGuard Rozemarijn"
  local usage="usage: wg-to-1password [-m machine] [-f] <file.conf> [home-subnet, e.g. 192.168.1.0/24]"
  local -a mopt fopt
  zparseopts -D -E -F m:=mopt -machine:=mopt f=fopt -force=fopt 2>/dev/null || { print -u2 $usage; return 1 }
  (( $# == 1 || $# == 2 )) || { print -u2 $usage; return 1 }
  local conf=$1 subnet=${2:-} force=${#fopt}
  [[ -r $conf ]] || { print -u2 "wg-to-1password: cannot read $conf"; return 1 }
  (( $+commands[op] )) || { print -u2 "wg-to-1password: op not installed (brew install --cask 1password-cli)"; return 1 }
  local machine=${mopt[-1]:-}
  if [[ -z $machine ]]; then
    machine=$(command chezmoi execute-template '{{ .purpose }}') && [[ -n $machine ]] \
      || { print -u2 "wg-to-1password: cannot read purpose from chezmoi; name the machine with -m"; return 1 }
  fi
  [[ $machine =~ '^[A-Za-z0-9_-]+$' ]] || { print -u2 "wg-to-1password: machine name '$machine' may only contain letters, digits, - and _"; return 1 }

  # value of the first `Key = value` line (keys are unique in a single-peer client config)
  local -A want=(private PrivateKey address Address public PublicKey endpoint Endpoint psk PresharedKey)
  local -A val
  local k line
  for k in ${(k)want}; do
    line=$(command grep -m1 -E "^[[:space:]]*${want[$k]}[[:space:]]*=" -- "$conf")
    val[$k]=${${line#*=}//[[:space:]]/}
  done
  for k in private address public endpoint; do
    [[ -n ${val[$k]} ]] || { print -u2 "wg-to-1password: no ${want[$k]} in $conf"; return 1 }
  done
  [[ -n ${val[psk]} ]] || { print -u2 "wg-to-1password: no PresharedKey in $conf (tick \"Pre-shared key\" for this client in UniFi and download again)"; return 1 }

  local -a machine_fields=(
    "$machine.private key[password]=${val[private]}"
    "$machine.address[text]=${val[address]}"
    "$machine.preshared key[password]=${val[psk]}"
  )
  local -a shared_fields=("server public key[text]=${val[public]}" "endpoint[text]=${val[endpoint]}")
  [[ -n $subnet ]] && shared_fields+=("allowed ips[text]=$subnet")

  print -r -- "Storing ${conf:t} as machine \"$machine\" in \"$item\" (account $account, vault $vault)."

  if ! command op item get "$item" --account "$account" --vault "$vault" >/dev/null 2>&1; then
    [[ -n $subnet ]] || { print -u2 "wg-to-1password: \"$item\" does not exist yet, so the home subnet is needed: wg-to-1password $conf 192.168.1.0/24"; return 1 }
    command op item create --account "$account" --category "Secure Note" --vault "$vault" --title "$item" $shared_fields $machine_fields >/dev/null || return 1
    print -r -- "Created \"$item\" with section \"$machine\"."
  else
    # What is there now. A field that does not exist yet reads as empty; filling it replaces nothing.
    local ref="op://$vault/$item" old
    local -a changes
    old=$(command op read --account "$account" "$ref/$machine/private key" 2>/dev/null)
    if [[ -n $old && $old != ${val[private]} ]]; then
      changes+=("section \"$machine\" already holds another client (address $(command op read --account "$account" "$ref/$machine/address" 2>/dev/null)); this file has address ${val[address]}")
    fi
    old=$(command op read --account "$account" "$ref/server public key" 2>/dev/null)
    [[ -n $old && $old != ${val[public]} ]] && changes+=("server public key: $old -> ${val[public]}")
    old=$(command op read --account "$account" "$ref/endpoint" 2>/dev/null)
    [[ -n $old && $old != ${val[endpoint]} ]] && changes+=("endpoint: $old -> ${val[endpoint]}")
    if [[ -n $subnet ]]; then
      old=$(command op read --account "$account" "$ref/allowed ips" 2>/dev/null)
      [[ -n $old && $old != $subnet ]] && changes+=("allowed ips: $old -> $subnet")
    fi
    if (( ${#changes} )); then
      print -r -- "This replaces what is in 1Password now:"
      print -rl -- "  - "${^changes}
      [[ ${changes[1]} == section* ]] && print -r -- "  A file for another machine? Name it: wg-to-1password -m <machine> ${conf:t}"
      if (( ! force )); then
        [[ -t 0 ]] || { print -u2 "wg-to-1password: not replacing without a terminal to ask on; use -f to replace anyway"; return 1 }
        read -q "?Replace? [y/N] " || { print; print -r -- "Nothing changed."; return 1 }
        print
      fi
    fi
    command op item edit "$item" --account "$account" --vault "$vault" $shared_fields $machine_fields >/dev/null || return 1
    print -r -- "Updated \"$item\": section \"$machine\"."
  fi
  print -r -- "Next, on the machine \"$machine\": chezmoi apply, then import ~/.config/wireguard/home.conf in the WireGuard app."
  print -r -- "The private key is now in 1Password: delete $conf."
}

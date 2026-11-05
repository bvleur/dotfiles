# 37-chezmoi-drift.zsh — one command for "what differs between this laptop and the dotfiles repo"
#
# chezmoi-drift    runs, in order: managed files and repo sync (below), then the specific drifts
#                    brewfile-drift             (36-brewfile.zsh)
#                    vicinae-shortcuts-drift    (38-vicinae-drift.zsh)
#                    vicinae-settings-drift     (38-vicinae-drift.zsh)
#                  Each of those can be run on its own. Add new ones to the list at the bottom.
#
# Every finding comes with a "→" line: the command that resolves it. Output helpers live in 35-drift-ui.zsh.
# Templates (.tmpl) are never re-added (that would overwrite the template with this laptop's rendered output):
# for those it suggests `chezmoi edit`, to copy the change into the template by hand.

# "~/path" for a path relative to $HOME, quoted when it contains spaces
_chezmoi_drift_target() {
  local p="~/$1"
  [[ $1 == *' '* ]] && p="\"\$HOME/$1\""
  print -r -- "$p"
}

# 0 when the source of a managed target is a template
_chezmoi_drift_is_template() {
  local srcfile
  srcfile=$(command chezmoi source-path "$HOME/$1" 2>/dev/null) || return 1
  [[ $srcfile == *.tmpl ]]
}

#: everything that differs between this laptop and the dotfiles repo, with fix commands
chezmoi-drift() {
  emulate -L zsh
  local _DRIFT_TTY; _drift_tty
  command -v chezmoi >/dev/null 2>&1 || { _drift_err "chezmoi not found"; return 1; }
  local src; src=$(command chezmoi source-path 2>/dev/null) || { _drift_err "no chezmoi source directory"; return 1; }
  _DRIFT_FOUND=0

  # the Vicinae settings have their own, more specific drift commands
  local skip='\.config/vicinae/settings\.json$'
  local -a status_lines
  status_lines=("${(@f)$(command chezmoi status 2>/dev/null)}")

  local line laptop repo rel target found

  # ── column 1 of `chezmoi status`: the file on this laptop differs from what chezmoi last wrote
  _drift_header "Managed files changed on this laptop since the last apply"
  found=0
  for line in $status_lines; do
    [[ -z $line || $line =~ $skip ]] && continue
    laptop=${line[1]} rel=${line[4,-1]}
    [[ $laptop == ' ' ]] && continue
    target=$(_chezmoi_drift_target "$rel")
    found=1
    case $laptop in
      D)
        _drift_item - "$rel  (deleted on this laptop)"
        _drift_fix "chezmoi apply $target" "restore it from the repo"
        _drift_fix "chezmoi forget $target" "or stop managing it"
        ;;
      *)
        if _chezmoi_drift_is_template "$rel"; then
          _drift_item '~' "$rel  (template)"
          _drift_fix "chezmoi diff $target" "see what changed"
          _drift_fix "chezmoi edit $target" "keep it: copy the change into the template by hand"
          _drift_fix "chezmoi apply --force $target" "or discard it: back to the repo version"
        else
          _drift_item '~' "$rel"
          _drift_fix "chezmoi re-add $target" "keep this laptop's version in the repo"
          _drift_fix "chezmoi apply --force $target" "or discard it: back to the repo version"
        fi
        ;;
    esac
  done
  (( found )) || _drift_ok "none"

  # ── column 2: applying would change the file (new in the repo, or a script that still has to run)
  print ""
  _drift_header "Not yet applied from the repo (chezmoi apply would change these)"
  found=0
  for line in $status_lines; do
    [[ -z $line || $line =~ $skip ]] && continue
    laptop=${line[1]} repo=${line[2]} rel=${line[4,-1]}
    [[ $repo == ' ' ]] && continue
    found=1
    case $repo in
      R) _drift_item + "$rel  (script, runs on apply)" ;;
      A) _drift_item + "$rel  (new)" ;;
      D) _drift_item - "$rel  (removed from the repo)" ;;
      *) _drift_item '~' "$rel" ;;
    esac
    [[ $laptop != ' ' ]] && _drift_note "  also changed on this laptop: resolve that first (see above), or apply overwrites it"
  done
  if (( found )); then
    _drift_fix "chezmoi diff" "review everything"
    _drift_fix "chezmoi apply" "apply it (single file: chezmoi apply ~/path)"
  else
    _drift_ok "none"
  fi

  # ── the source repo itself vs GitHub
  print ""
  _drift_header "Dotfiles repo vs GitHub"
  local fetched=1
  git -C "$src" fetch -q 2>/dev/null || fetched=0
  local dirty ahead behind
  dirty=$(git -C "$src" status --porcelain)
  ahead=$(git -C "$src" rev-list --count @{u}..HEAD 2>/dev/null) || ahead='?'
  behind=$(git -C "$src" rev-list --count HEAD..@{u} 2>/dev/null) || behind='?'

  if [[ -n $dirty ]]; then
    _drift_item '!' "uncommitted changes in $src:"
    print -r -- "$dirty" | while IFS= read -r line; do _drift_note "  $line"; done
    _drift_fix 'chezmoi git -- add -A && chezmoi git -- commit -m "…"' "commit them"
    _drift_fix 'lazygit -p "$(chezmoi source-path)"' "or review and commit in lazygit"
  fi
  if [[ $ahead == <-> && $behind == <-> ]] && (( ahead > 0 && behind > 0 )); then
    _drift_item '!' "$ahead commit(s) not pushed and $behind to pull (diverged)"
    _drift_fix "chezmoi git -- pull --rebase && chezmoi git -- push" "combine both sides"
    _drift_fix "chezmoi apply" "then apply what came in"
  elif [[ $ahead == <-> ]] && (( ahead > 0 )); then
    _drift_item + "$ahead commit(s) not pushed"
    _drift_fix "chezmoi git -- push"
  elif [[ $behind == <-> ]] && (( behind > 0 )); then
    _drift_item - "$behind commit(s) to pull"
    _drift_fix "chezmoi update" "pull and apply"
  fi
  [[ $ahead == '?' ]] && _drift_note "no upstream branch, can't compare with GitHub"
  (( fetched )) || _drift_note "fetch failed (offline?), comparing with the last known state of GitHub"
  [[ -z $dirty && $ahead == 0 && $behind == 0 ]] && _drift_ok "in sync"

  # ── specific drifts
  local drift
  for drift in brewfile-drift vicinae-shortcuts-drift vicinae-settings-drift; do
    print ""
    if (( ${+functions[$drift]} )); then
      $drift
    else
      _drift_err "$drift is not loaded"
    fi
  done

  # ── summary
  print ""
  if (( _DRIFT_FOUND )); then
    print -r -- "$(_drift_c bold)$(_drift_c yellow)$_DRIFT_FOUND item(s) to look at$(_drift_c reset)  $(_drift_c dim)run the → commands above$(_drift_c reset)"
  else
    print -r -- "$(_drift_c bold)$(_drift_c green)✓ this laptop matches the dotfiles repo$(_drift_c reset)"
  fi
  _drift_note "Config that chezmoi doesn't manage at all isn't checked: chezmoi unmanaged ~/.config, then chezmoi add <path>"
}

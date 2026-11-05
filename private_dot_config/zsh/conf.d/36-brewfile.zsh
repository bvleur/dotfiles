# 36-brewfile.zsh — Brewfile drift check (keep it hand-curated, avoid "installed then forgot to add")
#
# Workflow: brew install freely → occasionally `brewfile-drift` to see drift
#         → `brewfile-edit` to add keepers into the right section → chezmoi cd && git commit
# The Brewfile is a chezmoi template, at source dir .chezmoitemplates/Brewfile.

# absolute path to the source Brewfile (resolved lazily, not calling chezmoi at shell startup)
_brewfile_path() {
  local src
  src=$(command chezmoi source-path 2>/dev/null) || src="$HOME/.local/share/chezmoi"
  print -r -- "$src/.chezmoitemplates/Brewfile"
}

# render the Brewfile (it's a template) to stdout
_brewfile_render() {
  if command -v chezmoi >/dev/null 2>&1; then
    chezmoi execute-template < "$1"
  else
    cat "$1"
  fi
}

# single line → normalized key (aligns differences when comparing "system-state dump" vs "Brewfile")
_brewfile_key() {
  emulate -L zsh
  local line="${1%%#*}"                          # strip inline comment
  line="${line#"${line%%[![:space:]]*}"}"        # strip leading whitespace
  case "$line" in
    mas*)             [[ $line =~ 'id:[[:space:]]*([0-9]+)' ]] && print -r -- "mas:${match[1]}" ;;
    brew*|cask*|tap*) [[ $line =~ '"([^"]+)"' ]]               && print -r -- "${line%% *}:${match[1]}" ;;
  esac
}

#: compare installed Homebrew packages with the Brewfile
brewfile-drift() {
  emulate -L zsh
  local _DRIFT_TTY; _drift_tty
  command -v brew >/dev/null 2>&1 || { _drift_err "brew not found"; return 1; }
  local bf; bf=$(_brewfile_path)
  [[ -r $bf ]] || { _drift_err "Brewfile not found: $bf"; return 1; }

  typeset -A sys bfk ign        # ign: explicitly commented-out packages (deliberately ignored, no drift reported)
  local line key trimmed
  while IFS= read -r line; do
    key=$(_brewfile_key "$line"); [[ -n $key ]] && sys[$key]="$line"
  done < <(brew bundle dump --file=- --no-vscode 2>/dev/null)
  while IFS= read -r line; do
    trimmed="${line#"${line%%[![:space:]]*}"}"     # strip leading whitespace
    if [[ $trimmed == '#'* ]]; then
      # commented-out package line → add to ignore set
      trimmed="${trimmed#\#}"
      key=$(_brewfile_key "${trimmed#"${trimmed%%[![:space:]]*}"}")
      [[ -n $key ]] && ign[$key]=1
    else
      key=$(_brewfile_key "$line"); [[ -n $key ]] && bfk[$key]="$line"
    fi
  done < <(_brewfile_render "$bf")

  local found kind name
  local -a rm_tap rm_brew rm_cask rm_mas add_tap add_brew add_cask add_mas

  _drift_header "Installed but not in Brewfile"
  found=0
  for key in ${(ko)sys}; do
    (( ${+bfk[$key]} )) && continue          # already declared
    (( ${+ign[$key]} )) && continue          # explicitly commented, deliberately ignored
    _drift_item + "${sys[$key]}"; found=1
    kind=${key%%:*} name=${key#*:}
    case $kind in
      brew) rm_brew+=($name) ;;
      cask) rm_cask+=($name) ;;
      mas)  rm_mas+=($name) ;;
      tap)  rm_tap+=($name) ;;
    esac
  done
  if (( found )); then
    _drift_fix "brewfile-edit" "keep: copy the lines above into the right section"
    (( ${#rm_brew} )) && _drift_fix "brew uninstall ${rm_brew}" "or remove from this Mac"
    (( ${#rm_cask} )) && _drift_fix "brew uninstall --cask ${rm_cask}" "or remove from this Mac"
    (( ${#rm_mas} ))  && _drift_fix "sudo mas uninstall ${rm_mas}" "or remove from this Mac"
    (( ${#rm_tap} ))  && _drift_fix "brew untap ${rm_tap}" "or remove the tap"
    _drift_note "  to ignore one for good, add it to the Brewfile commented out (#cask \"name\")"
  else
    _drift_ok "none (system is fully tracked)"
  fi
  (( ${#ign} )) && _drift_note "(${#ign} commented-out item(s) ignored)"

  print ""
  _drift_header "In Brewfile but not installed"
  found=0
  for key in ${(ko)bfk}; do
    (( ${+sys[$key]} )) && continue
    _drift_item - "${bfk[$key]}"; found=1
    kind=${key%%:*} name=${key#*:}
    case $kind in
      brew) add_brew+=($name) ;;
      cask) add_cask+=($name) ;;
      mas)  add_mas+=($name) ;;
      tap)  add_tap+=($name) ;;
    esac
  done
  if (( found )); then
    _drift_fix 'chezmoi execute-template < "$(chezmoi source-path)/.chezmoitemplates/Brewfile" | brew bundle install --file=-' "install all of it (taps included)"
    (( ${#add_brew} )) && _drift_fix "brew install ${add_brew}" "or one by one"
    (( ${#add_cask} )) && _drift_fix "brew install --cask ${add_cask}"
    (( ${#add_mas} ))  && _drift_fix "mas install ${add_mas}" "signed in to the App Store"
    _drift_fix "brewfile-edit" "or drop it from the Brewfile"
  else
    _drift_ok "none (everything declared is installed)"
  fi
}

#: open the Brewfile in $EDITOR
brewfile-edit() { ${EDITOR:-nvim} "$(_brewfile_path)"; }

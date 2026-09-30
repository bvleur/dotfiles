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

# show drift between system and Brewfile
brewfile-drift() {
  emulate -L zsh
  command -v brew >/dev/null 2>&1 || { print -u2 "✗ brew not found"; return 1; }
  local bf; bf=$(_brewfile_path)
  [[ -r $bf ]] || { print -u2 "✗ Brewfile not found: $bf"; return 1; }

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

  local found
  print "── Installed but not in Brewfile (copy these in) ──"
  found=0
  for key in ${(ko)sys}; do
    (( ${+bfk[$key]} )) && continue          # already declared
    (( ${+ign[$key]} )) && continue          # explicitly commented, deliberately ignored
    print "  + ${sys[$key]}"; found=1
  done
  (( found )) || print "  ✓ none (system is fully tracked)"
  (( ${#ign} )) && print "  (${#ign} commented-out item(s) ignored)"

  print ""
  print "── In Brewfile but not installed (missing) ──"
  found=0
  for key in ${(ko)bfk}; do
    (( ${+sys[$key]} )) || { print "  - ${bfk[$key]}"; found=1; }
  done
  (( found )) || print "  ✓ none (everything declared is installed)"
}

# open the Brewfile for editing (used when adding drift items)
brewfile-edit() { ${EDITOR:-nvim} "$(_brewfile_path)"; }

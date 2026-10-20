# 37-chezmoi-drift.zsh — one command for "what differs between this laptop and the dotfiles repo"
#
# chezmoi-drift    runs, in order: managed files and repo sync (below), then the specific drifts
#                    brewfile-drift             (36-brewfile.zsh)
#                    vicinae-shortcuts-drift    (38-vicinae-drift.zsh)
#                    vicinae-settings-drift     (38-vicinae-drift.zsh)
#                  Each of those can be run on its own. Add new ones to the list at the bottom.
#
# Fixing what it shows: plain files → `chezmoi re-add <file>`; templates (.tmpl) → `chezmoi diff <file>` and copy by hand
# into the template (re-add would overwrite the template with this laptop's rendered output).

chezmoi-drift() {
  emulate -L zsh
  command -v chezmoi >/dev/null 2>&1 || { print -u2 "✗ chezmoi not found"; return 1; }
  local src; src=$(command chezmoi source-path 2>/dev/null) || return 1
  local line found
  # the Vicinae settings have their own, more specific drift commands
  local skip='\.config/vicinae/settings\.json$'

  print "── Managed files changed on this laptop since the last apply ──"
  found=0
  while IFS= read -r line; do
    [[ ${line[1]} == ' ' || $line =~ $skip ]] && continue
    print "  $line"; found=1
  done < <(chezmoi status 2>/dev/null)
  (( found )) || print "  ✓ none"

  print ""
  print "── Not yet applied from the repo (chezmoi apply would change these) ──"
  found=0
  while IFS= read -r line; do
    [[ ${line[2]} == ' ' || $line =~ $skip ]] && continue
    print "  $line"; found=1
  done < <(chezmoi status 2>/dev/null)
  (( found )) || print "  ✓ none"

  print ""
  print "── Dotfiles repo vs GitHub ──"
  git -C "$src" fetch -q 2>/dev/null
  local dirty ahead behind
  dirty=$(git -C "$src" status --porcelain)
  ahead=$(git -C "$src" rev-list --count @{u}..HEAD 2>/dev/null || print "?")
  behind=$(git -C "$src" rev-list --count HEAD..@{u} 2>/dev/null || print "?")
  [[ -n $dirty ]] && { print "  uncommitted changes in $src:"; print -r -- "$dirty" | sed 's/^/    /'; }
  (( ${ahead:-0} > 0 )) 2>/dev/null && print "  $ahead commit(s) not pushed"
  (( ${behind:-0} > 0 )) 2>/dev/null && print "  $behind commit(s) to pull (chezmoi update)"
  [[ -z $dirty && $ahead == 0 && $behind == 0 ]] && print "  ✓ in sync"

  # specific drifts
  local drift
  for drift in brewfile-drift vicinae-shortcuts-drift vicinae-settings-drift; do
    print ""
    (( ${+functions[$drift]} )) && $drift || print "  ✗ $drift is not loaded"
  done
}

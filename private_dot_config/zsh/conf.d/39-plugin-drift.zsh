# 39-plugin-drift.zsh — drift between the pinned zsh plugins and their repos on GitHub
#
# plugin-drift   for every `pin:` in .zsh_plugins.txt: is there a newer commit on the plugin's default branch?
#                `antidote update` skips pinned plugins (that is the point of a pin), so this is how you notice
#                updates for them. Unpinned plugins: `antidote update` updates them, `antidote update --dry-run`
#                (recent antidote) only shows what would change.
#
# Part of chezmoi-drift (37). Needs the network; offline it says so instead of reporting drift.

# "repo pin" for every pinned bundle line in the plugins file (also `preset:repo pin:...` lines)
_plugin_drift_pins() {
  local line repo pin
  local -a words
  while IFS= read -r line; do
    line=${line%%\#*}
    [[ $line == *pin:* ]] || continue
    words=(${=line})
    repo=${words[1]#preset:}
    pin=${${(M)words:#pin:*}[1]#pin:}
    [[ $repo == */* && -n $pin ]] && print -r -- "$repo $pin"
  done < "$1"
}

#: pinned zsh plugins that have a newer commit on GitHub, with the line to put in .zsh_plugins.txt
plugin-drift() {
  emulate -L zsh
  local _DRIFT_TTY; _drift_tty
  local file=${ZDOTDIR:-$HOME}/.zsh_plugins.txt
  [[ -r $file ]] || { _drift_err "no plugins file: $file"; return 1; }

  _drift_header "Pinned zsh plugins vs GitHub"
  local entry repo pin head found=0 offline=0
  local -a pins=("${(@f)$(_plugin_drift_pins $file)}")
  pins=(${pins:#})
  if (( ! ${#pins} )); then
    _drift_ok "no pinned plugins"
    return 0
  fi
  for entry in $pins; do
    repo=${entry%% *} pin=${entry#* }
    head=$(GIT_TERMINAL_PROMPT=0 command git ls-remote "https://github.com/$repo" HEAD 2>/dev/null)
    head=${head%%[[:space:]]*}
    if [[ -z $head ]]; then
      offline=1
      _drift_note "$repo: couldn't reach GitHub"
    elif [[ $head == $pin ]]; then
      _drift_ok "$repo (${pin[1,7]})"
    else
      found=1
      _drift_item '-' "$repo: newer commit on GitHub (pin ${pin[1,7]}, latest ${head[1,7]})"
      _drift_fix "open https://github.com/$repo/compare/$pin...$head" "see what changed"
      _drift_fix "chezmoi edit ~/.config/zsh/.zsh_plugins.txt" "update it: pin:$head, then a new shell"
    fi
  done
  (( offline )) && _drift_note "offline? the plugins that couldn't be reached weren't compared"
  return 0
}

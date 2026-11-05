# 38-vicinae-drift.zsh — drift between the Vicinae settings on this laptop and the chezmoi template
#
# vicinae-shortcuts-drift   global app shortcuts (providers.applications.entrypoints)
# vicinae-settings-drift    everything else in settings.json (theme, other providers, ...)
#
# Vicinae rewrites settings.json when you change something in its GUI. The source of truth is the template
# private_dot_config/vicinae/settings.json.tmpl (per purpose: home / bol): copy the change in there by hand.

_vicinae_settings_file() { print -r -- "$HOME/.config/vicinae/settings.json"; }

_vicinae_template_path() {
  local src
  src=$(command chezmoi source-path 2>/dev/null) || src="$HOME/.local/share/chezmoi"
  print -r -- "$src/private_dot_config/vicinae/settings.json.tmpl"
}

# JSONC → JSON: Vicinae writes // comment lines on top of the file
_vicinae_json() { grep -v '^[[:space:]]*//' | jq -S .; }

# the template rendered for this laptop's purpose, as JSON on stdout
_vicinae_template_json() { command chezmoi execute-template < "$(_vicinae_template_path)" | _vicinae_json; }

# 0 when both files exist and parse; prints why not otherwise
_vicinae_drift_ready() {
  local f; f=$(_vicinae_settings_file)
  command -v jq >/dev/null 2>&1 || { _drift_err "jq not found"; return 1; }
  [[ -r $f ]] || { _drift_err "no Vicinae settings on this laptop: $f"; return 1; }
  [[ -r $(_vicinae_template_path) ]] || { _drift_err "template not found: $(_vicinae_template_path)"; return 1; }
}

# how to resolve Vicinae drift: the settings file is a template, so changes are copied in by hand
_vicinae_drift_fixes() {
  _drift_fix "chezmoi edit ~/.config/vicinae/settings.json" "keep this laptop's change: copy it into the template (per purpose)"
  _drift_fix "chezmoi apply --force ~/.config/vicinae/settings.json" "or discard it: back to the template"
}

#: Vicinae app shortcuts: this laptop vs the chezmoi template
vicinae-shortcuts-drift() {
  emulate -L zsh
  local _DRIFT_TTY; _drift_tty
  _vicinae_drift_ready || return 1
  local laptop tmpl
  laptop=$(_vicinae_json < "$(_vicinae_settings_file)" | jq -c '.providers.applications.entrypoints // {}') || return 1
  tmpl=$(_vicinae_template_json | jq -c '.providers.applications.entrypoints // {}') || return 1

  _drift_header "Vicinae shortcuts: this laptop vs template"
  local out
  out=$(jq -nr --argjson l "$laptop" --argjson t "$tmpl" '
    def sc: if . == null then "(none)" else (.shortcut // "(no shortcut)") end;
    ( ($l | keys) - ($t | keys) | .[] | "+\tonly on this laptop: \(.)  \($l[.] | sc)" ),
    ( ($t | keys) - ($l | keys) | .[] | "-\tonly in template:    \(.)  \($t[.] | sc)" ),
    ( ($l | keys) as $lk | ($t | keys) | map(select(. as $k | $lk | index($k))) | .[]
      | select($l[.] != $t[.]) | "~\tdiffers: \(.)  laptop \($l[.] | sc), template \($t[.] | sc)" )
  ')
  if [[ -n $out ]]; then
    local kind text
    print -r -- "$out" | while IFS=$'\t' read -r kind text; do _drift_item "$kind" "$text"; done
    _vicinae_drift_fixes
  else
    _drift_ok "none (shortcuts match the template)"
  fi
}

#: other Vicinae settings: this laptop vs the chezmoi template
vicinae-settings-drift() {
  emulate -L zsh
  local _DRIFT_TTY; _drift_tty
  _vicinae_drift_ready || return 1
  local lf tf rc
  lf=$(mktemp) tf=$(mktemp)
  _vicinae_json < "$(_vicinae_settings_file)" | jq -S 'del(.providers.applications.entrypoints)' > "$lf"
  _vicinae_template_json | jq -S 'del(.providers.applications.entrypoints)' > "$tf"

  _drift_header "Other Vicinae settings: template (-) vs this laptop (+)"
  if diff -q "$tf" "$lf" >/dev/null; then
    _drift_ok "none (settings match the template)"
  else
    local line
    diff -u --label template --label laptop "$tf" "$lf" | tail -n +3 | while IFS= read -r line; do
      case $line in
        +*) print -r -- "  $(_drift_c green)$line$(_drift_c reset)" ;;
        -*) print -r -- "  $(_drift_c red)$line$(_drift_c reset)" ;;
        @@*) print -r -- "  $(_drift_c cyan)$line$(_drift_c reset)" ;;
        *)  print -r -- "  $(_drift_c dim)$line$(_drift_c reset)" ;;
      esac
    done
    _DRIFT_FOUND+=1
    _vicinae_drift_fixes
  fi
  rm -f "$lf" "$tf"
}

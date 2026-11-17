# 55-claude-cmd.zsh — text → zsh command via the Claude CLI (`claude -p`, so it uses the CLI's own gateway config)
#
#   ⌃G      generate, or modify an existing command with "command # instruction"
#   ⌃G      again: cycle through the 3 alternatives (no new call)
#   ⌃X e    explain the command in the buffer (empty buffer: the previous command)
#   ⌃X f    fix the previous command (optionally type a hint first, e.g. the error message)
#   ⌃_      undo (standard zle undo)
#
# Preferences: ~/.config/claude-cmd/prefs.md · features and design decisions: ~/.config/claude-cmd/README.md
# Loaded after the plugins (50) so these key bindings win. Every setting below can be overridden by setting
# the variable earlier (e.g. in 00-env.zsh).

(( $+commands[claude] )) || return 0

: ${CLAUDE_CMD_MODEL:=haiku}
: ${CLAUDE_CMD_LANG:=Dutch}
: ${CLAUDE_CMD_GLOW_STYLE:=dark}
: ${CLAUDE_CMD_PREFS:=${XDG_CONFIG_HOME:-$HOME/.config}/claude-cmd/prefs.md}
: ${CLAUDE_CMD_CACHE:=${XDG_CACHE_HOME:-$HOME/.cache}/claude-cmd}
: ${CLAUDE_CMD_KEY_GEN:='^G'}
# Ghostty sends ⌃; as the kitty-keyboard sequence ESC [ 59 ; 5 u (Terminal.app sends nothing for it),
# so the explain key is ⌃; there and ⌃X e everywhere else.
if [[ $TERM_PROGRAM == ghostty ]]; then
  : ${CLAUDE_CMD_KEY_EXPLAIN:=$'\e[59;5u'}
else
  : ${CLAUDE_CMD_KEY_EXPLAIN:='^Xe'}
fi
: ${CLAUDE_CMD_KEY_FIX:='^Xf'}
if [[ $TERM_PROGRAM == ghostty ]]; then
  : ${CLAUDE_CMD_KEY_HELP:=$'\e[59;6u'}
else
  : ${CLAUDE_CMD_KEY_HELP:=}   # empty: no key, use the claude-cmd-help command
fi
# Binaries checked individually, next to `brew leaves` (which gives package names, not binaries)
(( ${+CLAUDE_CMD_CANDIDATES} )) || typeset -ga CLAUDE_CMD_CANDIDATES=(
  rg fd bat eza zoxide fzf jq yq xh httpie sd delta dust duf procs btop hyperfine
  tldr gh glab git zed code docker podman kubectl k9s helm terraform aws gcloud az
  gsed gdate gfind gxargs gls gtar mise uv node npm pnpm bun python3 go java mvn gradle
)

zmodload zsh/parameter 2>/dev/null

typeset -ga _cc_alts _cc_labels
typeset -gi _cc_idx=0 _cc_last_status=0
typeset -g  _cc_os="$OSTYPE"
(( $+commands[sw_vers] )) && _cc_os="macOS $(sw_vers -productVersion 2>/dev/null) (BSD userland)"

# ── context ──────────────────────────────────────────────────────────────────

_cc_refresh_tools() {
  local f=$CLAUDE_CMD_CACHE/brew-leaves.txt
  mkdir -p $CLAUDE_CMD_CACHE
  if (( $+commands[brew] )); then
    brew leaves 2>/dev/null | tr '\n' ' ' >| $f.tmp && mv -f $f.tmp $f
  else
    : >| $f
  fi
}

_cc_tools_stale() {
  local -a fresh=( $CLAUDE_CMD_CACHE/brew-leaves.txt(Nmh-24) )
  (( ! ${#fresh} ))
}

_cc_context() {
  emulate -L zsh
  local leaves="" prefs="(geen)" gitinfo="" c
  local -a found
  [[ -r $CLAUDE_CMD_CACHE/brew-leaves.txt ]] && leaves=$(<$CLAUDE_CMD_CACHE/brew-leaves.txt)
  for c in $CLAUDE_CMD_CANDIDATES; do (( $+commands[$c] )) && found+=$c; done
  [[ -r $CLAUDE_CMD_PREFS ]] && prefs=$(<$CLAUDE_CMD_PREFS)
  if command git rev-parse --is-inside-work-tree &>/dev/null; then
    gitinfo=" (git repo, branch: $(command git branch --show-current 2>/dev/null))"
  fi
  print -r -- "OS: $_cc_os
Shell: zsh
Current directory: $PWD$gitinfo
Installed binaries (verified on PATH): ${found[*]}
Installed Homebrew packages (package names, not always binary names): ${leaves:-unknown}

User preferences:
$prefs"
}

# ── prompts ──────────────────────────────────────────────────────────────────

_cc_sys_commands() {
  print -r -- "You generate zsh commands for the user's machine, described in <context>.

Output EXACTLY 3 alternatives and nothing else, in this format:
@@@ <short label, max 4 words, in $CLAUDE_CMD_LANG>
<command>
@@@ <short label>
<command>
@@@ <short label>
<command>

Rules:
- The command lines contain only the command: no markdown, no code fences, no explanation, no comments.
- The first alternative is your best answer. The others must differ meaningfully: another tool, another approach, or a safer variant (dry run, interactive, narrower scope). No trivial variations.
- Use only binaries from the installed list or standard OS built-ins.
- Follow the user preferences strictly.
- Never invent options. When unsure an option exists in this OS's version of a tool, choose a different approach.
- Use sudo only when strictly necessary.
- Prefer a single line; use multiple lines only when unavoidable."
}

_cc_sys_explain() {
  print -r -- "Explain the given zsh command, in $CLAUDE_CMD_LANG, for the machine described in <context>.
Output GitHub-flavoured markdown, which is rendered in the terminal:
- Start with one sentence on what the command does as a whole.
- Then explain every relevant part (pipe stage, option, argument) in ONE markdown table with the columns Part and Meaning (column titles in $CLAUDE_CMD_LANG), one row per part, in command order. Put a sub-part such as an option of a pipe stage in its own row. No nested lists, no arrows.
- In table cells wrap every command, option and path in single backticks, and write a literal pipe character as \\| so it does not split the cell.
- Put multi-line snippets in fenced code blocks and always give the fence a language (\`\`\`sh).
- If the command is destructive or irreversible, end with a line starting with '⚠ ' that says what can be lost.
- If an option does not exist on this OS's version of the tool, say so explicitly.
- No headings, no preamble, no closing remarks. Keep every Meaning cell to one short sentence."
}

# ── claude ───────────────────────────────────────────────────────────────────

# $1 = system prompt, $2 = user message → stdout; stderr in $CLAUDE_CMD_CACHE/last-error
_cc_call() {
  mkdir -p $CLAUDE_CMD_CACHE
  print -r -- "$2" | command claude -p \
    --model "$CLAUDE_CMD_MODEL" \
    --system-prompt "$1" \
    --tools "" \
    --strict-mcp-config \
    --disable-slash-commands \
    --no-session-persistence \
    2>| $CLAUDE_CMD_CACHE/last-error
}

_cc_error_msg() {
  local err=""
  [[ -r $CLAUDE_CMD_CACHE/last-error ]] && err=${${(f)"$(<$CLAUDE_CMD_CACHE/last-error)"}[1]}
  print -rn -- "claude: geen bruikbaar antwoord${err:+ — $err}"
}

# Parse "@@@ label\ncommand…" blocks into _cc_alts / _cc_labels
_cc_parse() {
  emulate -L zsh
  setopt extendedglob
  _cc_alts=() _cc_labels=()
  local line cur="" label="" started=0 nl=$'\n'
  local -a lines=( "${(@f)1}" )

  _cc_flush() {
    while [[ $cur == [[:space:]]* ]]; do cur=${cur[2,-1]}; done
    while [[ $cur == *[[:space:]] ]]; do cur=${cur[1,-2]}; done
    if [[ -n $cur ]]; then _cc_alts+=("$cur"); _cc_labels+=("$label"); fi
    cur=""
  }

  for line in "${lines[@]}"; do
    if [[ $line == '@@@'* ]]; then
      (( started )) && _cc_flush
      label=${${line#@@@}##[[:space:]]#}; started=1
    elif [[ $line == '```'* ]]; then
      continue
    elif (( started )); then
      cur+="${cur:+$nl}$line"
    fi
  done
  if (( started )); then
    _cc_flush
  else
    # the model ignored the format: treat the whole output as one alternative
    cur=${(F)${lines:#'```'*}}; label=""; _cc_flush
  fi
  unfunction _cc_flush
}

# Markdown on stdin → coloured text on stdout, via glow (same invocation as the yazi previewer and `v`).
# Fences without a language are treated as `sh`, so shell snippets always get syntax highlighting.
# Falls back to the raw markdown when glow is missing.
_cc_render() {
  local md
  md=$(command awk '
    /^[[:space:]]*```[[:space:]]*$/ { if (!open) { sub(/```.*/, "```sh") } open = !open; print; next }
    /^[[:space:]]*```/              { open = 1 }
    { print }
  ')
  if (( $+commands[glow] )); then
    print -r -- "$md" | CLICOLOR_FORCE=1 command glow -w=${COLUMNS:-80} -s=$CLAUDE_CMD_GLOW_STYLE -
  else
    print -r -- "$md"
  fi
}

# ── info bar ──────────────────────────────────────────────────────────────────

_cc_keylabel() {
  local k=$1 r
  if [[ $k == $'\e[59;5u' ]]; then
    print -rn -- '⌃;'
  elif [[ $k == $'\e[59;6u' ]]; then
    print -rn -- '⌃⇧;'
  elif [[ $k == '^['?* ]]; then
    print -rn -- "⌥${(U)k[3,-1]}"
  elif [[ $k == '^'?* ]]; then
    r=${k[3,-1]}; print -rn -- "⌃${(U)k[2]}${r:+ $r}"
  else
    print -rn -- $k
  fi
}

_cc_hints() {  # $1 = label for the generate key
  print -rn -- "$(_cc_keylabel $CLAUDE_CMD_KEY_GEN) ${1:-genereer}   $(_cc_keylabel $CLAUDE_CMD_KEY_EXPLAIN) uitleg   $(_cc_keylabel $CLAUDE_CMD_KEY_FIX) fix vorige   ⌃_ ongedaan"
}

_cc_is_destructive() {
  emulate -L zsh
  local -a res=(
    '(^|[[:space:];&|(])(sudo[[:space:]]+)?(rm|rmdir|dd|shred|truncate|diskutil|kill|killall|pkill|mkfs[.a-z0-9]*)([[:space:]]|$)'
    '(^|[[:space:]])(-rf|-fr|--force|--delete|--hard|--no-preserve-root|-delete)([[:space:]]|$)'
    '-exec[[:space:]]+rm'
    'git[[:space:]]+(clean|reset[^;|]*--hard|push[^;|]*(--force|-f)|checkout[[:space:]]+--[[:space:]]|restore)'
    '(chmod|chown)[[:space:]]+-R'
    '(DROP|TRUNCATE)[[:space:]]+(TABLE|DATABASE)'
  )
  local re
  for re in $res; do
    [[ $1 =~ $re ]] && return 0
  done
  return 1
}

# Plain-text messages (info bar, progress, errors) go in POSTDISPLAY: zle draws it under the prompt line, and it
# is cleared again when the line is accepted (see _cc_line_finish). Empty $1 clears it. No ANSI colour here:
# zle prints escape codes in POSTDISPLAY literally.
_cc_bar() {
  if [[ -n $1 ]]; then POSTDISPLAY=$'\n'"$1"; else POSTDISPLAY=""; fi
  zle -R
}

_cc_line_finish() { POSTDISPLAY="" }
autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-finish _cc_line_finish

_cc_show() {
  BUFFER=${_cc_alts[_cc_idx]}
  CURSOR=$#BUFFER
  local warn="" label=${_cc_labels[_cc_idx]}
  _cc_is_destructive "$BUFFER" && warn="⚠ destructief — lees goed voor je Enter drukt
"
  _cc_bar "${warn}✦ claude ${_cc_idx}/${#_cc_alts}${label:+ · $label}   │   $(_cc_hints volgende)"
}

_cc_busy() {
  _cc_bar "⏳ claude ($CLAUDE_CMD_MODEL) $1…"
}

# ── widgets ──────────────────────────────────────────────────────────────────

_cc_request() {  # $1 = user message
  local out
  out=$(_cc_call "$(_cc_sys_commands)" "<context>
$(_cc_context)
</context>

$1")
  _cc_parse "$out"
  if (( ! ${#_cc_alts} )); then
    _cc_bar "$(_cc_error_msg)"
    return 1
  fi
  _cc_idx=1
  _cc_show
}

#: zle widget (^G): turn the typed description into a command, repeat to cycle alternatives
claude-cmd-generate() {
  # Cycle: the buffer is still exactly the current alternative
  if (( ${#_cc_alts} > 1 && _cc_idx )) && [[ $BUFFER == ${_cc_alts[_cc_idx]} ]]; then
    _cc_idx=$(( _cc_idx % ${#_cc_alts} + 1 ))
    _cc_show
    return
  fi
  if [[ -z ${BUFFER//[[:space:]]/} ]]; then
    _cc_bar "claude: typ eerst wat je wilt doen   │   $(_cc_hints)"
    return
  fi
  _cc_busy "denkt na"
  _cc_request "Input (natural-language request, an existing command to fix/improve, or a command followed by '# <instruction>' to modify it accordingly):
$BUFFER"
}

#: zle widget (^Xe): explain the command on the line, or the previous one
claude-cmd-explain() {
  local target=$BUFFER
  [[ -z ${target//[[:space:]]/} ]] && target=${history[$(( HISTCMD - 1 ))]}
  if [[ -z $target ]]; then
    _cc_bar "claude: niets om uit te leggen"
    return
  fi
  _cc_busy "legt uit"
  local out
  out=$(_cc_call "$(_cc_sys_explain)" "<context>
$(_cc_context)
</context>

Command:
$target")
  if [[ -z ${out//[[:space:]]/} ]]; then
    _cc_bar "$(_cc_error_msg)"
  else
    # Coloured markdown can't go in POSTDISPLAY (zle shows the escape codes literally), so print it above
    # the prompt; the plain-text bottom area is only cleared of its progress line.
    zle -I
    print -r -- "$(print -r -- "$out" | _cc_render)"
    _cc_bar ""
  fi
}

#: zle widget (^Xf): fix the previous failed command
claude-cmd-fix() {
  local last=${history[$(( HISTCMD - 1 ))]}
  if [[ -z $last ]]; then
    _cc_bar "claude: geen vorig commando gevonden"
    return
  fi
  local hint=${BUFFER//[[:space:]]/}
  hint=${hint:+$BUFFER}
  _cc_busy "repareert"
  _cc_request "Fix the previous command so it does what the user intended.
Previous command (exit status $_cc_last_status):
$last
User hint about what went wrong: ${hint:-none}"
}

_cc_precmd() { _cc_last_status=$? }
precmd_functions=(_cc_precmd ${precmd_functions:#_cc_precmd})

zle -N claude-cmd-generate
zle -N claude-cmd-explain
zle -N claude-cmd-fix
bindkey "$CLAUDE_CMD_KEY_GEN" claude-cmd-generate
bindkey "$CLAUDE_CMD_KEY_EXPLAIN" claude-cmd-explain
bindkey "$CLAUDE_CMD_KEY_FIX" claude-cmd-fix
[[ -n $CLAUDE_CMD_KEY_HELP ]] && { zle -N claude-cmd-help-widget; bindkey "$CLAUDE_CMD_KEY_HELP" claude-cmd-help-widget; }

# ── helper commands ────────────────────────────────────────────────────────────

#: edit the claude-cmd preferences (preferred CLI tools, option style) via chezmoi
claude-cmd-prefs() {
  if (( $+commands[chezmoi] )) && chezmoi source-path "$CLAUDE_CMD_PREFS" &>/dev/null; then
    chezmoi edit --apply "$CLAUDE_CMD_PREFS"
  else
    ${=EDITOR:-vi} "$CLAUDE_CMD_PREFS"
  fi
}

#: refresh the list of installed tools that claude-cmd sends as context
claude-cmd-refresh() {
  _cc_refresh_tools && print -r -- "claude-cmd: toollijst ververst ($(wc -w <$CLAUDE_CMD_CACHE/brew-leaves.txt | tr -d ' ') Homebrew-pakketten)"
}

#: show exactly what context claude-cmd sends to Claude
claude-cmd-context() { _cc_context }

#: overview of the widget's keys, rendered as markdown; calls no model
claude-cmd-help() {
  emulate -L zsh
  local help helprow=""
  [[ -n $CLAUDE_CMD_KEY_HELP ]] && helprow="| \`$(_cc_keylabel $CLAUDE_CMD_KEY_HELP)\` | Deze help. |"$'\n'
  help="# claude-cmd

| Toets | Wat |
|---|---|
| \`$(_cc_keylabel $CLAUDE_CMD_KEY_GEN)\` | Maak een commando van de tekst in de buffer. Wijzig een bestaand commando met \`commando # instructie\`. |
| \`$(_cc_keylabel $CLAUDE_CMD_KEY_GEN)\` nog eens | Volgend alternatief van de drie (lokaal, geen nieuwe aanvraag). |
| \`$(_cc_keylabel $CLAUDE_CMD_KEY_EXPLAIN)\` | Leg het commando in de buffer uit (leeg: het vorige commando). |
| \`$(_cc_keylabel $CLAUDE_CMD_KEY_FIX)\` | Repareer het vorige commando. Typ eerst een hint, bijvoorbeeld de foutmelding. |
| \`⌃_\` | Ongedaan maken. |
${helprow}
Helpers: \`claude-cmd-prefs\`, \`claude-cmd-refresh\`, \`claude-cmd-context\`."
  if (( $+commands[glow] )); then
    print -r -- "$help" | CLICOLOR_FORCE=1 command glow -w=${COLUMNS:-80} -s=$CLAUDE_CMD_GLOW_STYLE -
  else
    print -r -- "$help"
  fi
}

#: zle widget for the help key: shows the overview above the prompt, without a model call
claude-cmd-help-widget() {
  zle -I
  claude-cmd-help
  _cc_bar ""
}

# Refresh the tool list at most once per 24 hours, in the background
_cc_tools_stale && { _cc_refresh_tools &! } 2>/dev/null

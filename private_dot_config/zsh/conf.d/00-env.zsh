# # --- XDG base directories (10/40 already depend on these implicitly; defined here) ---
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# --- completion paths (cross-platform, must apply before compinit (10)) ---
# Homebrew prefix: Apple Silicon /opt/homebrew, Intel /usr/local (unless brew shellenv already set it)
if [[ -z ${HOMEBREW_PREFIX-} ]]; then
  [[ -d /opt/homebrew ]] && HOMEBREW_PREFIX=/opt/homebrew || HOMEBREW_PREFIX=/usr/local
fi
[[ -d $HOMEBREW_PREFIX/share/zsh/site-functions ]] && FPATH=$HOMEBREW_PREFIX/share/zsh/site-functions:$FPATH

# --- help (70): extra files whose `#:` description lines it lists; plugins loaded in 50 can add themselves ---
typeset -gaU HELP_SOURCES   # -U: a file added twice (e.g. a reloaded plugin) is kept once

# --- claude-cmd-deluxe (loaded by antidote in 50; settings must come before it) ---
CLAUDE_CMD_LANG=Dutch

# --- editor ---
export EDITOR=nvim
export VISUAL=nvim

# pay-respects: never send anything to its AI service (offline rules only; ccd covers the Claude-based fix)
export _PR_AI_DISABLE=1

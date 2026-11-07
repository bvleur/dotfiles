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

# --- editor ---
export EDITOR=nvim
export VISUAL=nvim

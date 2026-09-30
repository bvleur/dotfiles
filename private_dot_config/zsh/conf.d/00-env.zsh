# # --- XDG base directories (10/40 already depend on these implicitly; defined here) ---
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# --- completion paths (cross-platform, must apply before compinit (10)) ---
[[ -d /opt/homebrew/share/zsh/site-functions ]]  && FPATH=/opt/homebrew/share/zsh/site-functions:$FPATH

# --- editor ---
export EDITOR=nvim
export VISUAL=nvim

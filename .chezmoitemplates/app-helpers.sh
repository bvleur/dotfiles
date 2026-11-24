# Shared shell helpers for .chezmoiscripts that need to stop or (re)start a macOS app.
# Use it from a script with the includeTemplate function and the name of this file, after `set -eu`.
# See CLAUDE.md for the exact line. Never write the literal template action in this file:
# chezmoi parses the whole file as a template, so it would include itself forever.
# Process name and app name are assumed to be the same (true for Snapzy, Vicinae, Rectangle).
#
# All helpers are best-effort: they always return 0, so a restart problem can never
# fail `chezmoi apply`. Worst case the app picks up its new config on its next start.
#
#   restart_app NAME  restart NAME only if it is running (config is read at launch)
#   stop_app NAME     quit NAME if running and wait until it is gone
#   start_app NAME    launch NAME, retrying; warns instead of failing

# pkill instead of an AppleScript quit: no Automation permission prompt
stop_app() {
  pkill -x "$1" >/dev/null 2>&1 || true
  for _ in $(seq 1 20); do
    pgrep -x "$1" >/dev/null 2>&1 || break
    sleep 0.5
  done
  return 0
}

# Right after the process exits, LaunchServices may not have cleaned up yet and
# `open` fails with error -600 (procNotFound), so pause briefly and retry.
start_app() {
  sleep 1
  for _ in 1 2 3 4 5; do
    open -a "$1" >/dev/null 2>&1 && return 0
    sleep 1
  done
  echo "warning: could not launch $1; start it manually to load the new config" >&2
  return 0
}

restart_app() {
  pgrep -x "$1" >/dev/null 2>&1 || return 0
  echo "==> Restarting $1 to load changes..."
  stop_app "$1"
  start_app "$1"
}

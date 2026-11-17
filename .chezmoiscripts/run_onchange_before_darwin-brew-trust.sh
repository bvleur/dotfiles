#!/bin/bash
# Trusts the third-party Homebrew formulae from the Brewfile BEFORE `brew bundle` runs (see the install-packages script).
# Newer Homebrew refuses to load formulae from non-official taps until they are trusted ("Refusing to load formula … from
# untrusted tap"). We trust only the single formula, not the whole tap, so the rest of that tap stays refused.
# Why not `trusted: true` in the Brewfile: it is reported as unreliable inside `brew bundle` (Homebrew/brew#22631).
# Never fails: Homebrew too old for `brew trust`, or a managed laptop that forbids it, must not break `chezmoi apply`.
# Rerun by hand: chezmoi state delete-bucket --bucket=scriptState && chezmoi apply  (or just run the lines below)
set -u

if ! command -v brew >/dev/null 2>&1; then
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$b" ]; then eval "$("$b" shellenv)"; break; fi
  done
fi
command -v brew >/dev/null 2>&1 || exit 0

# Homebrew without the trust mechanism has no `brew trust`: nothing to do there.
brew trust --help >/dev/null 2>&1 || exit 0

# format: <tap> <formula>; add new third-party formulae here (keep in sync with the Brewfile)
while read -r tap formula; do
  brew tap "$tap" >/dev/null 2>&1 || true
  brew trust --formula "$formula" || echo "!! could not trust $formula (brew bundle may refuse it); try: brew trust $tap" >&2
done <<'LIST'
timescam/tap timescam/tap/pay-respects
LIST
exit 0

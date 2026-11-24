# Conventions for this chezmoi repo

- Everything in the repo (scripts, comments, prompts, commits, PRs) is written in English.
- Use chezmoi features as intended; make changes in small batches.
- Scripts in `.chezmoiscripts/` that stop, start or restart a macOS app must use the shared helpers
  from `.chezmoitemplates/app-helpers.sh` (`restart_app NAME`, `stop_app NAME`, `start_app NAME`) via
  `{{ includeTemplate "app-helpers.sh" . }}`. Do not hand-roll `pkill` / `open -a` loops: the helpers wait for
  the quit, retry the launch (macOS error -600) and never fail `chezmoi apply`. Fix problems in the helper, not per script.
- Never let a best-effort step (restart, reload) abort `chezmoi apply`.

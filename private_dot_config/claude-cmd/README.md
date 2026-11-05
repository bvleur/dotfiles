# claude-cmd

A zsh widget that turns text into a shell command, or modifies an existing command, through the Claude CLI (`claude -p`, Haiku by default).

## Features

| Key | What |
|---|---|
| `⌃G` | Generate 3 alternatives from the text in the buffer; the best one goes into the buffer. Modify an existing command with `command # instruction`. |
| `⌃G` (again) | Cycle through the 3 alternatives, locally, without a new call. |
| `⌃X e` | Explain the command in the buffer (empty buffer: the previous command). The buffer stays as it is. |
| `⌃X f` | Fix the previous command, with its exit status as context. Optionally type a hint first (e.g. the error message). |
| `⌃_` | Undo (standard zle undo). |

- **Info bar:** after every action, `zle -M` shows the position (`1/3`), the label of the alternative and the shortcuts under the prompt.
- **Warning:** for destructive commands (`rm`, `--force`, `git reset --hard`, …) the info bar adds a ⚠ line.
- **Helper commands:**
  - `claude-cmd-prefs`: edit the preferences, through `chezmoi edit --apply`.
  - `claude-cmd-refresh`: refresh the tool list.
  - `claude-cmd-context`: show the context Claude receives.

## Decisions

- **Through `claude -p`, not the API.** Everything automatically goes through the Claude CLI's gateway config. No separate API key or endpoint is needed.
- **Own widget instead of an existing plugin.** The existing plugins are thin wrappers. With our own widget we don't depend on a hobby project, and we can tweak commands, show alternatives and pass preferences.
- **3 alternatives in one call.** Faster than asking again, because `claude -p` takes 1–3 seconds to start. The alternatives must differ meaningfully: another tool, another approach, or a safe variant.
- **Never execute automatically.** The command always goes into the buffer, and you press Enter yourself.
- **Context per call:**
  - the preferences from `prefs.md`;
  - installed tools: `brew leaves`, cached for at most 24 hours and refreshed in the background, plus a fixed candidate list checked against `$PATH`;
  - OS, cwd and git branch.

  Deliberately left out: the full contents of `$PATH` (too large), aliases (they don't work outside your shell) and `--help` output (too heavy).
- **Preferences in a separate file, managed in chezmoi.** A tool list says nothing about preference, so `rg` over `grep` is stated explicitly in `prefs.md`. The rule for long-form options lives there too.
- **Long-form options where possible, never invented.** The macOS base tools are BSD; GNU options only through the `g`-variants when installed.
- **Info bar through `zle -M`, no Ghostty escape codes.** It works in any terminal. A bar at the very bottom of the window would need scroll-region tricks, which break on resize.
- **Shortcuts `⌃X e` / `⌃X f` instead of Alt.** `⌥F` is `forward-word` by default, and Alt only works in Ghostty with `macos-option-as-alt`. All keys are configurable.
- **Deliberately left out:**
  - autosuggest while typing (too slow and too expensive through `claude -p`);
  - chat mode;
  - capturing the output of the previous command (requires `script` wrapping).

## Where things live

| File | Contents |
|---|---|
| `~/.config/zsh/conf.d/55-claude-cmd.zsh` | the widget; loaded after the plugins (50) so its key bindings win |
| `~/.config/claude-cmd/prefs.md` | preferences; edit with `claude-cmd-prefs` |
| `~/.config/claude-cmd/README.md` | this file |
| `~/.cache/claude-cmd/` | cached `brew leaves` and the last error message |

The widget does nothing when `claude` isn't on `PATH`, so it is safe on both MacBooks.

## Settings (set before 55, e.g. in `00-env.zsh`)

| Variable | Default |
|---|---|
| `CLAUDE_CMD_MODEL` | `haiku` |
| `CLAUDE_CMD_LANG` | `Dutch` (language of explanations and labels) |
| `CLAUDE_CMD_KEY_GEN` / `_EXPLAIN` / `_FIX` | `^G` / `^Xe` / `^Xf` |
| `CLAUDE_CMD_CANDIDATES` | array of individual binaries to check |

## Known limitations

- `⌃C` while waiting aborts the whole line.
- If your gateway doesn't know the `haiku` alias, set a full model ID in `CLAUDE_CMD_MODEL`.

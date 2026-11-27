# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io).

Based on:
- blog post: https://www.shiinayane.com/en/posts/dotfiles/
- repo: https://github.com/shiinayane/dotfiles-public/

---

## What's included

| File / directory | Purpose |
|---|---|
| `private_dot_config/zsh/` | Zsh configuration, split into `conf.d/` fragments |
| `.chezmoitemplates/Brewfile` | Homebrew package list, installed via `brew bundle` |
| `private_dot_config/yazi/` | yazi: `.docx` preview ([doxx.yazi](https://github.com/bgreenwell/doxx.yazi)), `.md` preview with glow (piper), `gi` opens lazygit, text files open in Zed ([lazygit.yazi](https://github.com/Lil-Dank/lazygit.yazi)); plugins (list in the `run_onchange_after_darwin-yazi-plugins` chezmoi script, which runs `ya pkg add`/`install`; the `doxx` binary comes from the Brewfile) |
| `private_dot_config/{bat,ghostty,yazi,zed}` theme files | One colour theme everywhere: Gruvbox. Everything is always dark (the light Gruvbox is too yellow): Ghostty and Zed use Gruvbox Dark Hard when macOS is light and Gruvbox Dark when it is dark; bat and yazi are always Gruvbox Dark. bat (`config`), Ghostty (`config`, its ANSI palette also colours eza, lazygit, fzf, ...), yazi (`theme.toml`, community flavor `gmvar/gruvbox-dark` installed by the yazi plugins script) Zed (theme + auto-installed extension); JetBrains Mono is the font everywhere (Nerd Font build via the Brewfile cask, Ghostty, Zed; IntelliJ ships the plain one) and, on the work laptop, IntelliJ by hand (Settings > Plugins > Marketplace > "Gruvbox Islands - Theme", then Settings > Appearance > Theme with "Sync with OS"; deliberately not scripted: `idea installPlugins` starts a full IDE instance that can leave a stale config lock behind) |
| `.chezmoiscripts/` | Script that automatically runs `brew bundle` on `chezmoi apply` |
| `.chezmoitemplates/RectangleConfig.json` | Rectangle settings (its export format): only fn⌃⌘← / fn⌃⌘→ (= ⌃⌘Home / ⌃⌘End on a keyboard with those keys) to move a window to the previous / next display, fn⌃⌘↑ / fn⌃⌘↓ to maximize / center, fn⌃⌥⌘↑ / fn⌃⌥⌘↓ to make it larger / smaller — next to macOS' own fn⌃-arrow tiling, all other Rectangle shortcuts and drag-to-snap off. Applied by `run_onchange_after_darwin-rectangle-config.sh`; grant Rectangle Accessibility access once per Mac |
| `private_dot_config/claude-cmd/prefs.md` | Preferences for [claude-cmd-deluxe](https://github.com/bvleur/claude-cmd-deluxe) (loaded as an antidote plugin, `CLAUDE_CMD_LANG=Dutch` in `00-env.zsh`): in Ghostty ⌃; turns text into a shell command and ⌃⇧; opens a menu (e explain, E explain in a pager, f fix the previous command, h all keys); elsewhere ⌃G, ⌃X e, ⌃X f. `prefs.md` holds the preferred tools and option style |

### Machine type (`purpose`)

Some configuration is machine-specific, controlled by the `purpose` variable. `chezmoi init` asks for it once (via [`.chezmoi.toml.tmpl`](.chezmoi.toml.tmpl)) and stores the answer in `~/.config/chezmoi/chezmoi.toml` (a local file, **not** committed to the repo).

| Value | Use |
|---|---|
| `"bol"` | Work laptop — also installs bol-specific tools (JetBrains, gcloud, kubectx, …) |
| `"home"` | Personal laptop — general tools only |

On a `home` machine `chezmoi init` also asks `server` (yes/no). `server = true` adds server / remote-build extras on top of home (`tmux`, `xcodes`, `xcbeautify`, plus a `sudo` script that disables sleep, enables SSH, checks that Screen Sharing is on and prints the manual steps: Xcode via `xcodes`, `gh auth login`); everything else stays identical. It is always `false` for `bol`. Change an answer later with `chezmoi init --prompt`.

On every machine that is not a server, `chezmoi init` also asks `vpn` (yes/no, default no). `vpn = true` installs the WireGuard app (Mac App Store). The client config for the home network is not a chezmoi-managed file: `vpn-config` writes `~/.config/wireguard/rozemarijn.conf` from 1Password (item `WireGuard Rozemarijn`, vault `Private`, account `vleur.1password.com`), so `chezmoi apply` never depends on 1Password. Fill the item from the `.conf` that UniFi generates with `wg-to-1password [-m machine] <file.conf> [home-subnet]`. `help vpn` in the shell shows the whole setup and daily use.

---

## Installing on a new machine

Run this single command and follow the prompt:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/bvleur/dotfiles/main/install.sh)
```

The script will:
1. Install Homebrew if not already present
2. Install chezmoi via Homebrew
3. Run `chezmoi init --apply`, which asks whether this is a `home` or `bol` machine

> **Note:** For `purpose = "bol"`, the private Homebrew tap (`gitlab.bol.io`) must be reachable. Make sure your SSH key for GitLab is set up, or skip the tap and add it manually later.

### Manual fallback

<details>
<summary>Step-by-step without the script</summary>

**1. Install Homebrew** (if not present):
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**2. Install chezmoi:**
```bash
brew install chezmoi
```

**3. Initialize and apply** (chezmoi asks for the machine type, `home` or `bol`):
```bash
chezmoi init --apply https://github.com/bvleur/dotfiles.git
```

**4.** Sign in to the App Store and install `mas` apps if needed (requires Apple ID).

</details>

---

## Daily usage

| Command | What it does |
|---|---|
| `help` | Lists my custom aliases and functions by category (system config, files, git, ccd, then the rest). `help --all` also shows the rarely used ones, `help <text>` searches all. Descriptions are `#: [category] …` comment lines above each alias / function in `conf.d/*.zsh`; `#: [category, more] …` marks a rarely used one. Internal helpers get a leading `_` and stay hidden; `help --check` lists public names that still lack a description |
| `dots` | Opens the chezmoi source directory in Zed |
| `v <file>...` | Views files with the best installed viewer: `.md` via glow, `.docx` via doxx (same as the yazi previews), `.json` via jless, `.csv`/`.tsv` via csvlens, binary files via hexyl, directories via your `ls` alias (`ls -l`), everything else via bat (falls back to `less`); `v --help` lists the table |
| `ccd-prefs` | Edit the ccd preferences (preferred CLI tools, long-form options) through chezmoi |
| `chezmoi edit <file>` | Edit a dotfile through chezmoi |
| `chezmoi apply` | Apply changes to the system |
| `chezmoi diff` | Preview what would change before applying |
| `chezmoi-drift` | Everything that differs between this laptop and the repo (files, git, Brewfile, Vicinae, pinned zsh plugins), each with the commands to fix it |
| `plugin-drift` | Pinned zsh plugins (`pin:` in `.zsh_plugins.txt`) that have a newer commit on GitHub, with the new pin; `antidote update` skips pinned plugins |
| `brewfile-drift` | Compare installed packages against the Brewfile |
| `brewfile-edit` | Open the Brewfile in `$EDITOR`; when you changed it, shows the command to commit it |

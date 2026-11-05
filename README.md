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
| `.chezmoiscripts/` | Script that automatically runs `brew bundle` on `chezmoi apply` |
| `.chezmoitemplates/RectangleConfig.json` | Rectangle settings (its export format): only fn⌃⌘← / fn⌃⌘→ (= ⌃⌘Home / ⌃⌘End on a keyboard with those keys) to move a window to the previous / next display, fn⌃⌘↑ / fn⌃⌘↓ to maximize / center, fn⌃⌥⌘↑ / fn⌃⌥⌘↓ to make it larger / smaller — next to macOS' own fn⌃-arrow tiling, all other Rectangle shortcuts and drag-to-snap off. Applied by `run_onchange_after_darwin-rectangle-config.sh`; grant Rectangle Accessibility access once per Mac |
| `private_dot_config/zsh/conf.d/55-claude-cmd.zsh` + `private_dot_config/claude-cmd/` | claude-cmd: ⌃G turns text into a shell command (or tweaks one with `command # instruction`) via `claude -p` (Haiku), with 3 alternatives to cycle through; ⌃X e explains, ⌃X f fixes the previous command. Preferred tools and option style live in `prefs.md`; features and decisions in its `README.md` |

### Machine type (`purpose`)

Some configuration is machine-specific, controlled by the `purpose` variable in `~/.config/chezmoi/chezmoi.toml` (a local file, **not** committed to the repo).

| Value | Use |
|---|---|
| `"bol"` | Work laptop — also installs bol-specific tools (JetBrains, gcloud, kubectx, …) |
| `"home"` | Personal laptop — general tools only |

---

## Installing on a new machine

Run this single command and follow the prompt:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/bvleur/dotfiles/main/install.sh)
```

The script will:
1. Install Homebrew if not already present
2. Install chezmoi via Homebrew
3. Ask whether this is a `home` or `bol` machine
4. Write `~/.config/chezmoi/chezmoi.toml` accordingly
5. Run `chezmoi init` and `chezmoi apply`

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

**3. Set the machine type** — create `~/.config/chezmoi/chezmoi.toml` before applying:

Personal laptop:
```bash
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml << 'EOF'
[data]
  purpose = "home"
EOF
```

Work laptop (bol):
```bash
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml << 'EOF'
[data]
  purpose = "bol"
EOF
```

**4. Initialize and apply:**
```bash
chezmoi init https://github.com/bvleur/dotfiles.git
chezmoi apply
```

**5.** Sign in to the App Store and install `mas` apps if needed (requires Apple ID).

</details>

---

## Daily usage

| Command | What it does |
|---|---|
| `help` | Lists my custom aliases and functions with a description (`help <text>` filters). Descriptions are `#: …` comment lines above each alias / function in `conf.d/*.zsh`. Internal helpers get a leading `_` and stay hidden; `help --check` lists public names that still lack a description |
| `dots` | Opens the chezmoi source directory in Zed |
| `claude-cmd-prefs` | Edit the claude-cmd preferences (preferred CLI tools, long-form options) through chezmoi |
| `chezmoi edit <file>` | Edit a dotfile through chezmoi |
| `chezmoi apply` | Apply changes to the system |
| `chezmoi diff` | Preview what would change before applying |
| `chezmoi-drift` | Everything that differs between this laptop and the repo (files, git, Brewfile, Vicinae), each with the commands to fix it |
| `brewfile-drift` | Compare installed packages against the Brewfile |
| `brewfile-edit` | Open the Brewfile in `$EDITOR`; when you changed it, shows the command to commit it |

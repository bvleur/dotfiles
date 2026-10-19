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
| `.chezmoiscripts/` | Script that automatically runs `brew bundle` on `chezmoi apply` |

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
| `dots` | Opens the chezmoi source directory in Zed |
| `chezmoi edit <file>` | Edit a dotfile through chezmoi |
| `chezmoi apply` | Apply changes to the system |
| `chezmoi diff` | Preview what would change before applying |
| `brewfile-drift` | Compare installed packages against the Brewfile |
| `brewfile-edit` | Open the Brewfile in `$EDITOR` |

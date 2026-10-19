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

### 1. Prerequisites

- macOS
- Internet connection
- For `purpose = "bol"`: access to `gitlab.bol.io` (VPN or corporate network) for the private Homebrew tap

### 2. Install chezmoi and initialize the repo

```bash
# Install chezmoi (bootstraps itself, no Homebrew required)
sh -c "$(curl -fsLS get.chezmoi.io)"

# Initialize from the repo (replace with your repo URL)
chezmoi init https://github.com/<your-username>/dotfiles.git
```

### 3. Set the machine type

Create `~/.config/chezmoi/chezmoi.toml` **before** running `chezmoi apply`:

**Personal laptop:**
```bash
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml << 'EOF'
[data]
  purpose = "home"
EOF
```

**Work laptop (bol):**
```bash
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml << 'EOF'
[data]
  purpose = "bol"
EOF
```

### 4. Apply the configuration

```bash
chezmoi apply
```

This also automatically installs Homebrew (if not present) and runs `brew bundle`.

> **Note:** For `purpose = "bol"`, the private Homebrew tap (`gitlab.bol.io`) must be reachable. Make sure your SSH key for GitLab is set up, or skip the tap and add it manually later.

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

---

## New machine checklist

```
1. Install chezmoi
2. chezmoi init <repo-url>
3. Create chezmoi.toml with purpose = "home" or "bol"
4. chezmoi apply
5. Sign in to the App Store and install mas apps if needed (requires Apple ID)
```

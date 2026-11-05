# claude-cmd preferences
<!-- Managed in chezmoi. Edit with: claude-cmd-prefs -->

## Tools (use these when installed)
- Search file contents: rg, not grep
- Find files: fd, not find
- View files: bat; in pipes and scripts plain cat
- Directory listing: eza, not ls
- Open or edit files: zed <path>
- JSON: jq; YAML: yq
- HTTP: xh for interactive use, curl in scripts
- Find-and-replace in files: sd, not sed -i
- Disk usage: dust; free space: duf
- GitHub: gh

## Style
- Use long-form options (--ignore-case, --hidden, --recursive) when the tool supports them. Use short flags only when no long form exists.
- Never invent options. The macOS base tools (ls, find, sed, cp, xargs, date, stat) are BSD versions without most GNU options; use GNU options only through the g-variant (gsed, gdate, gfind) when it is installed.
- No sudo unless strictly necessary.
- For destructive actions, make one of the alternatives a safe variant (dry run, interactive, or first show what will be affected).
- Always quote paths that contain spaces.

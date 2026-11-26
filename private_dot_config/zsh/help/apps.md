# Apps that need a manual step

After `chezmoi update` (`cu`) a short warning appears when an app from the Brewfile is not fully set up, for
example **LinearMouse: Accessibility not granted yet**. Run the full report any time with `app-check`.
It only warns: it never fails `chezmoi apply`.

## What is checked

| App | Needs | Why |
| --- | --- | --- |
| LinearMouse | Accessibility | read and change mouse events |
| Rectangle | Accessibility | move and resize other apps' windows |
| Vicinae | Accessibility, Full Disk Access | window and file search, paste into the front app |
| Snapzy | Screen Recording (also: finish its welcome screen) | screenshots and screen recordings |
| Ghostty | Full Disk Access | lets the 1Password CLI (`op`) and `systemsetup` work from the terminal |
| WireGuard | installed (only with the `vpn` flag) | the home VPN client |
| GitHub CLI | signed in (`gh auth login`) | `gh`, lazygit and friends |

Every app must also be installed. All of this applies to every Mac (home, work laptop, Mac mini); the work laptop
simply has no Claude apps in the list because chezmoi does not install them there.

## Grant a permission

System Settings > Privacy & Security > the pane named in the warning, then switch the app on. The warning
prints a ready-made `open "x-apple.systempreferences:…"` command that jumps straight to that pane.
Some apps need a restart after you grant Accessibility or Screen Recording.

## How the check works, and its limits

- Permissions are read from macOS's privacy database (TCC). That only works when the terminal you run it in has
  **Full Disk Access**. Without it, `app-check` says so and skips the permission checks; it never claims
  that something is missing when it simply cannot look.
- A permission that has no row in the system database is reported as `?` (cannot verify), not as missing: some
  grants (seen with Rectangle) do not show up there although System Settings shows them as on. A row that says
  "off" is reliable and is reported as a problem. Only when the per-user database can be read too does "no row"
  count as "not granted yet".
- Camera, microphone, calendars, contacts and Automation cannot be read reliably from a script, so they are only
  listed as reminders in the full `app-check` report.
- Login items (start at login) cannot be read without an admin prompt, so they are not checked.
- The app list lives in `dot_local/bin/executable_app-check.tmpl` in the dotfiles repo: add a line when you add
  an app that needs a permission.

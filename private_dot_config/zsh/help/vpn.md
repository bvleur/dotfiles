# VPN to the home network

WireGuard to the UniFi gateway at home. Only traffic for the home subnet goes through the tunnel.
The config is rendered by chezmoi; every secret lives in 1Password (item `WireGuard Rozemarijn`, vault `Private`).

## Connect (daily use)

1. Click the WireGuard icon in the menu bar and pick the `rozemarijn` tunnel, or open the WireGuard app and press
   **Activate**.
2. Reach the Mac mini by its home address: `ssh <user>@<mini-ip>`, or Screen Sharing with `open vnc://<mini-ip>`.
3. Disconnect the same way (**Deactivate**).

Screen Sharing asks for your own account name and password on the mini; nobody has to accept anything there.
After a restart of the mini the disk is still locked (FileVault): unlock it first with `ssh <user>@<mini-ip>`
and your account password, then connect again.

## Sign in to 1Password on the command line

1. Open the 1Password app > Settings > Developer and turn on **Integrate with 1Password CLI**.
2. Give your terminal app (Ghostty) **Full Disk Access**: System Settings > Privacy & Security > Full Disk Access.
   Quit the terminal with Cmd+Q and open it again. Without it `op` cannot read the app's settings and reports
   "No accounts configured" (`op --debug vault list` shows `settings.json: operation not permitted`).
3. Run `op vault list`. Approve the prompt (Touch ID); it should list the `Private` vault.
4. More than one account on this machine (work + personal) is fine: the VPN config and `wg-to-1password`
   always use `vleur.1password.com`. For your own `op` commands add `--account vleur.1password.com`.

`chezmoi apply` needs this whenever it renders the VPN config. A locked 1Password just prompts again.

## Set up a new machine (once)

1. UniFi Network > Settings > VPN > VPN Server > your WireGuard server: add a client for this machine, tick
   **Pre-shared key**, and download its `.conf` file. One client per machine, never a shared one.
2. Answer yes to the VPN question: `chezmoi init`. It only asks what this machine has not answered yet.
   To change an earlier answer: `chezmoi init --prompt` (needs a recent chezmoi; otherwise set `vpn = true`
   under `[data]` with `chezmoi edit-config`).
3. Sign in to 1Password on the command line (see above).
4. Store the downloaded file in 1Password, on the machine the file is for:
   - first machine: `wg-to-1password ~/Downloads/<file>.conf <home-subnet>`, e.g. `192.168.1.0/24`
   - any later machine: `wg-to-1password ~/Downloads/<file>.conf`
   - a file for another machine than the one you are on: add `-m bol` or `-m home`

   Each machine has its own section in the item (`bol`, `home`). The command says which section it writes, and
   asks before it replaces anything that is already there.
5. Delete the downloaded `.conf`: it contains this machine's private key.
6. `chezmoi apply` installs the WireGuard app and writes `~/.config/wireguard/rozemarijn.conf`.
7. WireGuard app > **Import Tunnel(s) from File...** > `~/.config/wireguard/rozemarijn.conf`, and allow the VPN
   configuration when macOS asks.

## When something is off

- **`op` says "No accounts configured"** although the integration is on: the terminal lacks Full Disk Access
  (see above).
- **`chezmoi apply` fails on `rozemarijn.conf`**: 1Password is not signed in or the item is incomplete. Check with
  `op read --account vleur.1password.com "op://Private/WireGuard Rozemarijn/endpoint"`.
- **Changed the item or the template**: run `chezmoi apply`, then remove the tunnel in the WireGuard app and
  import the file again. The app keeps its own copy.
- **Connected but the mini does not answer**: check that `allowed ips` in the item is the home subnet, and that
  no other VPN (the work VPN) claims the same range.
- **Lost or leaked a config**: delete that client in UniFi, create a new one and run `wg-to-1password` again.

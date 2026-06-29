# macbookair — nix-darwin system config

Declarative macOS config for `macbookair` (Apple M2): **nix-darwin + home-manager + flakes**, on
**Determinate Nix**, pinned to the **stable 26.05** channel. Homebrew (driven by nix-darwin) handles
GUI casks + the Mac App Store.

## Layout

| File | Owns |
|------|------|
| `flake.nix` | inputs (nixpkgs-26.05-darwin, nix-darwin-26.05, home-manager release-26.05, determinate) + the `macbookair` config |
| `darwin.nix` | system: Determinate module (caches + auto-GC), macOS defaults, hostname, Touch-ID sudo (+ tmux reattach), fonts |
| `homebrew.nix` | 14 casks + 6 Mac App Store apps |
| `home.nix` | packages, zsh/starship/fzf/zoxide, git (+ssh signing), ssh, **nh**, **direnv**, dotfiles |
| `dotfiles/` | vendored configs (ghostty, fastfetch) |
| `starship.toml` | prompt config (read via `fromTOML`) |
| `justfile` | `switch` / `update` / `check` / `rollback` / `secrets` (via `nh`) |

## What's NOT managed here (by design)
- **Secrets** — 1Password (SSH agent + `op`). Repo holds only references → safe to publish.
- **nvim config** — existing `~/.config/nvim` (LazyVim), left writable; only deps installed.
- **SSH-Ghostty.app handler** — built once via the repo's `install.sh` (interactive TCC grant).
- **Wallpaper, Claude MCP config, Xcode, ExpressVPN/Flameshot/qBittorrent** — left manual.

## Updates & automation
- **Nix itself + garbage collection** → managed by Determinate Nixd automatically (disk-pressure GC, keeps ≥30 GB free). Nix self-update is detected; apply with `sudo determinate-nixd upgrade`.
- **Casks** → upgrade on each `switch` (`homebrew.onActivation.upgrade`).
- **flake inputs** → bump via the **`update-flake-lock` GitHub Action** (weekly cron → opens a PR; CI builds it; you review + merge). *Recommended over unattended switching.* Add `.github/workflows/update-flake-lock.yml` once the repo is pushed.
- **The rebuild itself** → run `just switch` (= `nh darwin switch`, shows a diff + asks first). Unattended auto-switch is intentionally not configured.

---

## Bootstrap (fresh machine)

> Order matters. Nix eval never needs secrets; only runtime does.

### 0. Manual prerequisites
1. Install **1Password**, sign in. Enable Settings → Developer → **SSH agent** + **Integrate with CLI**.
2. Ensure your GitHub SSH key is in 1Password (served by the agent).
3. **Sign into the App Store** (for `mas`).
4. Confirm **FileVault** on; store the recovery key in 1Password.

### 1. Install Determinate Nix
```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate
```
Flakes on by default. (Caches + GC are declared in `darwin.nix` — no manual `nix.conf` editing.)

### 2. Get this repo
```sh
git clone <your-private-remote> ~/nix-config && cd ~/nix-config
```

### 3. Adopt already-installed apps (avoid cask collisions)
```sh
for app in google-chrome whatsapp discord notion slack claude proton-mail \
           ghostty tailscale adguard 1password; do
  brew install --cask --adopt "$app"
done
```
(`cyberduck`/`keka` install fresh; `1password-cli` already a brew cask.)

### 4. First switch (bootstraps darwin-rebuild + renames host to `macbookair`)
```sh
sudo nix run nix-darwin -- switch --flake .#macbookair
```
Thereafter: `just switch`.

### 5. Retire old brew formulae + drop replaced apps
```sh
brew uninstall chromedriver crossover
brew uninstall $(brew leaves)          # old CLI — now from nix
# remove App Store copies replaced by casks: WhatsApp, Keka (+ Termius, legacy)
```

### 6. Flip Homebrew cleanup to declarative
Once verified, set `homebrew.onActivation.cleanup = "zap";` in `homebrew.nix` and `just switch`.

### 7. SSH-Ghostty handler (one-time, interactive)
```sh
cd /path/to/ghostty-ssh-handler && ./install.sh   # NOT --configs (configs come from nix)
```
Then click an `ssh://` link and approve the "control Ghostty" dialog once.

### 8. Secrets + final bits
```sh
just secrets                                   # op read -> ~/.config/<app>/<file>
mkdir -p ~/Pictures/Wallpapers && mv ~/Downloads/Silver_Dyn_Mac.heic ~/Pictures/Wallpapers/
```
Create `~/.ssh/config.local` (gitignored) with your work hosts (bastion, ProxyJump).

---

## Daily use
```sh
just switch      # nh darwin switch — diff + confirm, then apply
just update      # bump flake.lock + switch
just check       # build without activating
just rollback    # undo last switch
```

## Recovery
- A broken config fails at **build**, before activation — system untouched.
- `just rollback` → previous generation.
- `git checkout <good> && just switch` → reproduce a known-good state.
- Brew survives a full Nix uninstall, so GUI apps persist.

## Footguns to know
- **`backupFileExtension`**: if a stale `*.hm-bak` exists from a prior run, activation fails — delete the stale backup by hand and re-switch.
- **`homebrew.onActivation.upgrade = true`** makes `switch` non-idempotent (upgrades casks each run) — flip to `false` + occasional `brew upgrade` if you prefer.

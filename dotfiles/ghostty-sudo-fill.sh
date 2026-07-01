#!/usr/bin/env bash
# Touch-ID sudo autofill for Ghostty.
# Reads a sudo password from 1Password (Touch ID via the 1Password app CLI
# integration), then types it into the focused Ghostty terminal and presses Enter.
# Bind to a hotkey (skhd) and fire it at a "[sudo] password:" prompt.
#
# The 1Password item reference is kept machine-local (not in this repo):
#   echo 'GHOSTTY_SUDO_OP_REF=op://<vault>/<item>/password' > ~/.config/ghostty-sudo-fill.env
set -euo pipefail

# skhd launches with a minimal PATH; make op + osascript resolvable.
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:${PATH:-}"

env_file="$HOME/.config/ghostty-sudo-fill.env"
# shellcheck source=/dev/null
[ -f "$env_file" ] && . "$env_file"

note() { osascript -e "display notification \"$1\" with title \"sudo-fill\"" >/dev/null 2>&1 || true; }

if [ -z "${GHOSTTY_SUDO_OP_REF:-}" ]; then
  note "Set GHOSTTY_SUDO_OP_REF in ~/.config/ghostty-sudo-fill.env"
  exit 1
fi

if ! pw="$(op read "$GHOSTTY_SUDO_OP_REF" 2>/dev/null)" || [ -z "$pw" ]; then
  note "op read failed (unlock 1Password / check item ref)"
  exit 1
fi

# Pass the secret via env (not argv) so it never appears in ps output.
PW="$pw" osascript <<'OSA' >/dev/null 2>&1
set pw to system attribute "PW"
tell application "Ghostty"
	set term to focused terminal of selected tab of front window
	input text pw to term
	send key "enter" to term
end tell
OSA

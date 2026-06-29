# macbookair nix-config — run from ~/nix-config
# `just` with no args lists recipes.

default:
    @just --list

# rebuild + activate (nh shows a diff + asks before applying)
switch:
    nh darwin switch .

# update flake inputs, then rebuild (nh: diff + confirm)
update:
    nh darwin switch . --update

# build only — validate without activating
check:
    nh darwin build .

# roll back to the previous generation
rollback:
    sudo darwin-rebuild --rollback

# list generations
generations:
    darwin-rebuild --list-generations

# pull file-secrets from 1Password (needs `op` signed in + biometric).
# Adjust the op:// reference to match your vault/item.
secrets:
    @mkdir -p ~/.config/<app>
    op read "op://Private/<item>/<field>" > ~/.config/<app>/<file>
    @chmod 600 ~/.config/<app>/<file>
    @echo "secrets pulled"

# NOTE: garbage collection is automatic (Determinate Nixd, disk-pressure-based).
# Force a manual GC only if needed:  nh clean all --keep 5 --keep-since 7d

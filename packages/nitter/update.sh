#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix
set -euo pipefail

info() {
    if [ -t 2 ]; then
        set -- '\033[32m%s\033[39m\n' "$@"
    else
        set -- '%s\n' "$@"
    fi
    printf "$@" >&2
}

# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/doc/languages-frameworks/nim.section.md#lockfiles-nim-lockfiles
info "in mystia repo, running custom update script."
info "building src drv..."
nix build .#nitterExperimental.src

info "generating lockfile..."
nix run nixpkgs#nim_lk ./result | jq --sort-keys > lock.json
info "done."


#!/usr/bin/env bash
set -euo pipefail

REPO="$HOME/dotfiles"
GITHUB="https://github.com/marcosxaviergil/marcosxavier-dotfiles.git"
FORGEJO="https://forgejo.consciencia.dev.br/marcosxavier/marcosxavier-dotfiles.git"

[ -d "$REPO/.git" ] || exit 0

# fetch aponta para o GitHub
git -C "$REPO" remote set-url origin "$GITHUB"

# Limpa push URLs existentes e reconfigura push duplo (idempotente)
git -C "$REPO" config --unset-all remote.origin.pushurl 2>/dev/null || true
git -C "$REPO" remote set-url --add --push origin "$GITHUB"
git -C "$REPO" remote set-url --add --push origin "$FORGEJO"

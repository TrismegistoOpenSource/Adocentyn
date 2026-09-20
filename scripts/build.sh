#!/usr/bin/env bash
# Prepara in build/ la copia pronta all'uso, senza artefatti in sourcecode/.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$(cd "$SRC/.." && pwd)/build"

rm -rf "$OUT"
mkdir -p "$OUT"

cp -R "$SRC/bootstrap.sh" "$SRC/install.sh" "$SRC/lib" "$SRC/steps" \
      "$SRC/dotfiles" "$SRC/README.md" "$SRC/LICENSE" "$OUT/"

chmod +x "$OUT/bootstrap.sh" "$OUT/install.sh" "$OUT"/steps/*.sh
chmod +x "$OUT"/dotfiles/dot_local/bin/executable_*

printf '==> build pronta in %s\n' "$OUT"

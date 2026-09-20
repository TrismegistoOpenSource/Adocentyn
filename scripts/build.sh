#!/usr/bin/env bash
# Prepara in build/ l'archivio distribuibile, senza artefatti in sourcecode/.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$(cd "$SRC/.." && pwd)/build"
# shellcheck source=../lib/utils.sh
source "$SRC/lib/utils.sh"

NOME="adocentyn-$ADOCENTYN_VERSION"

rm -rf "$OUT"
mkdir -p "$OUT"

# git archive prende esattamente ciò che è committato in HEAD: niente .DS_Store
# né file di lavoro dimenticati. Le modifiche non ancora committate non entrano.
git -C "$SRC" archive --format=tar.gz --prefix="$NOME/" -o "$OUT/$NOME.tar.gz" HEAD

printf '==> %s/%s.tar.gz\n' "$OUT" "$NOME"
printf '    Nota: l'"'"'archivio non è un repository git, quindi "chezmoi update"\n'
printf '    non funziona da lì. Per l'"'"'uso normale si clona il repo.\n'

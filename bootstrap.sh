#!/usr/bin/env bash
# Adocentyn - punto di ingresso da una Debian netinst appena installata.
# Installa il minimo per scaricare il repo, lo clona e lancia l'installazione.
#
#   apt install -y curl
#   curl -fsSL https://raw.githubusercontent.com/TrismegistoOpenSource/Adocentyn/main/bootstrap.sh | bash
set -euo pipefail

REPO_URL="${ADOCENTYN_REPO:-https://github.com/TrismegistoOpenSource/Adocentyn.git}"
CHECKOUT="${ADOCENTYN_DIR:-/opt/adocentyn}"
BRANCH="${ADOCENTYN_BRANCH:-main}"

if [ "$(id -u)" -ne 0 ]; then
    printf 'ERRORE: serve root (accedi come root oppure usa sudo)\n' >&2
    exit 1
fi

printf '\n==> Adocentyn - preparazione\n'

# Una netinst minima non ha né git né i certificati: senza questi il clone
# fallisce con un errore TLS che sembra un problema di rete.
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git ca-certificates curl

if [ -d "$CHECKOUT/.git" ]; then
    printf '==> aggiorno il checkout esistente in %s\n' "$CHECKOUT"
    git -C "$CHECKOUT" fetch --depth 1 origin "$BRANCH"
    git -C "$CHECKOUT" checkout -B "$BRANCH" "origin/$BRANCH"
else
    printf '==> clono %s in %s\n' "$REPO_URL" "$CHECKOUT"
    rm -rf "$CHECKOUT"
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$CHECKOUT"
fi

# curl|bash lascia stdin occupato dalla pipe: l'installer diventa muto ai
# prompt e ogni "read" legge il resto dello script. Gli ridiamo il terminale.
if [ -r /dev/tty ]; then
    exec bash "$CHECKOUT/install.sh" "$@" </dev/tty
else
    exec bash "$CHECKOUT/install.sh" "$@"
fi

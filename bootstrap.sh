#!/usr/bin/env bash
# Adocentyn - scorciatoia per chi ha già curl sul sistema.
#
# Su una netinst minima NON c'è né git né curl: la via normale è installare git
# a mano e clonare il repo (vedi README). Questo script serve solo a evitare
# quei due passaggi quando curl c'è già.
set -euo pipefail

REPO_URL="${ADOCENTYN_REPO:-https://github.com/TrismegistoOpenSource/Adocentyn.git}"
CHECKOUT="${ADOCENTYN_DIR:-/opt/adocentyn}"
BRANCH="${ADOCENTYN_BRANCH:-main}"

if [ "$(id -u)" -ne 0 ]; then
    printf 'ERRORE: serve root (accedi come root oppure usa sudo)\n' >&2
    exit 1
fi

printf '\n==> Adocentyn - preparazione\n'

if ! DEBIAN_FRONTEND=noninteractive apt-get update ||
   ! DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends git ca-certificates; then
    printf 'ERRORE: apt non riesce a installare git.\n' >&2
    printf 'Probabilmente il sistema non ha repository di rete: vedi la sezione\n' >&2
    printf '"Se apt install git fallisce" nel README del progetto.\n' >&2
    exit 1
fi

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

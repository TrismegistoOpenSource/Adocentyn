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

# Prima di poter installare git servono dei repository funzionanti. Se
# l'installazione è stata fatta senza mirror di rete non ce ne sono, e apt
# fallisce: in quel caso li scriviamo qui, perché senza git non possiamo
# nemmeno scaricare lo step 01 che farebbe la stessa cosa fatta meglio.
if ! apt-get update 2>/dev/null || ! apt-cache show git >/dev/null 2>&1; then
    printf '==> nessun repository di rete configurato, lo aggiungo\n'
    cat > /etc/apt/sources.list.d/debian.sources <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
    if [ -f /etc/apt/sources.list ] && grep -q '^deb cdrom:' /etc/apt/sources.list; then
        sed -i 's|^deb cdrom:|# deb cdrom:|' /etc/apt/sources.list
    fi
    DEBIAN_FRONTEND=noninteractive apt-get update
fi

DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git ca-certificates

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

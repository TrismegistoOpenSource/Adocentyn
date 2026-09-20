#!/usr/bin/env bash
# Step 01 - componenti non-free e repository backports.
set -euo pipefail
# shellcheck source=../lib/utils.sh
source "${ADOCENTYN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/utils.sh"

step "01 - repository"

SOURCES="/etc/apt/sources.list.d/debian.sources"
BACKPORTS="/etc/apt/sources.list.d/debian-backports.sources"

# Un'installazione fatta senza mirror di rete non ha questo file (ha solo il
# CD in /etc/apt/sources.list): senza, nemmeno "apt install git" funziona.
if [ ! -f "$SOURCES" ]; then
    cat > "$SOURCES" <<'EOF'
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
    ok "$SOURCES creato (mancava: installazione fatta senza mirror di rete)"

    # Il CD non serve più e, se non è nel lettore, fa fallire ogni apt update.
    if [ -f /etc/apt/sources.list ] && grep -q '^deb cdrom:' /etc/apt/sources.list; then
        sed -i 's|^deb cdrom:|# deb cdrom:|' /etc/apt/sources.list
        ok "sorgente CD-ROM disattivata"
    fi
fi

if grep -q 'non-free-firmware' "$SOURCES"; then
    skip "contrib/non-free/non-free-firmware già attivi"
else
    cp -n "$SOURCES" "${SOURCES}.bak"
    sed -i -E 's/^Components:(.*)$/Components:\1 contrib non-free non-free-firmware/' "$SOURCES"
    grep -q 'non-free-firmware' "$SOURCES" || {
        cp "${SOURCES}.bak" "$SOURCES"
        die "nessuna riga 'Components:' in $SOURCES: backup ripristinato, serve modifica a mano"
    }
    ok "contrib, non-free e non-free-firmware attivati (backup in ${SOURCES}.bak)"
fi

# Hyprland non esiste in Trixie stable: l'intero stack arriva dai backports
# ufficiali (0.55.2), l'unica versione Debian che regge la config in Lua.
if [ -f "$BACKPORTS" ]; then
    skip "backports già configurati"
else
    cat > "$BACKPORTS" <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
    ok "trixie-backports aggiunto"
fi

info "apt update"
DEBIAN_FRONTEND=noninteractive apt-get update
ok "indice dei pacchetti aggiornato"

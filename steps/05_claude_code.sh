#!/usr/bin/env bash
# Step 05 - Claude Code dal repository apt firmato di Anthropic.
set -euo pipefail
# shellcheck source=../lib/utils.sh
source "${ADOCENTYN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/utils.sh"

step "05 - Claude Code"

KEYRING="/etc/apt/keyrings/claude-code.asc"
LIST="/etc/apt/sources.list.d/claude-code.list"
FINGERPRINT="31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE"

apt_install gnupg

chiave_valida() {
    [ -f "$KEYRING" ] && \
        gpg --show-keys --with-colons "$KEYRING" 2>/dev/null | grep -q "$FINGERPRINT"
}

NUOVE_SORGENTI=0

if chiave_valida; then
    skip "chiave già presente e verificata"
else
    install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://downloads.claude.ai/keys/claude-code.asc -o "$KEYRING"

    # Una chiave scaricata e non verificata vale quanto nessuna chiave: se il
    # download è stato intercettato o troncato, ce ne accorgiamo adesso.
    if ! chiave_valida; then
        rm -f "$KEYRING"
        die "l'impronta della chiave non corrisponde a $FINGERPRINT: installazione interrotta"
    fi
    ok "chiave scaricata e verificata"
    NUOVE_SORGENTI=1
fi

RIGA="deb [signed-by=$KEYRING] https://downloads.claude.ai/claude-code/apt/stable stable main"
if [ -f "$LIST" ] && [ "$(cat "$LIST")" = "$RIGA" ]; then
    skip "repository già configurato"
else
    printf '%s\n' "$RIGA" > "$LIST"
    ok "repository configurato"
    NUOVE_SORGENTI=1
fi

# apt update solo se le sorgenti sono cambiate davvero: su un aggiornamento
# normale lo step 01 lo ha già fatto poco fa.
if [ "$NUOVE_SORGENTI" = "1" ]; then
    DEBIAN_FRONTEND=noninteractive apt-get update
fi

apt_install claude-code

ok "claude-code $(dpkg-query -W -f='${Version}' claude-code 2>/dev/null || echo '?')"
info "al primo avvio serve il login: lancia 'claude' da utente normale"

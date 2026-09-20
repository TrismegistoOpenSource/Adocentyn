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

install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://downloads.claude.ai/keys/claude-code.asc -o "$KEYRING"

# Una chiave scaricata e non verificata vale quanto nessuna chiave: se il
# download è stato intercettato o troncato, ce ne accorgiamo adesso.
if ! gpg --show-keys --with-colons "$KEYRING" 2>/dev/null | grep -q "$FINGERPRINT"; then
    rm -f "$KEYRING"
    die "l'impronta della chiave non corrisponde a $FINGERPRINT: installazione interrotta"
fi
ok "chiave verificata"

echo "deb [signed-by=$KEYRING] https://downloads.claude.ai/claude-code/apt/stable stable main" > "$LIST"
DEBIAN_FRONTEND=noninteractive apt-get update
apt_install claude-code

ok "claude-code $(dpkg-query -W -f='${Version}' claude-code 2>/dev/null || echo '?')"
info "al primo avvio serve il login: lancia 'claude' da utente normale"

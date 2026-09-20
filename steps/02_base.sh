#!/usr/bin/env bash
# Step 02 - sistema di base: audio, rete, permessi, dischi, font.
set -euo pipefail
# shellcheck source=../lib/utils.sh
source "${ADOCENTYN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/utils.sh"

step "02 - base del sistema"

apt_install \
    pipewire pipewire-pulse pipewire-audio wireplumber \
    network-manager network-manager-gnome \
    polkitd udisks2 gvfs gvfs-backends \
    fonts-jetbrains-mono fonts-font-awesome fonts-noto-color-emoji \
    git curl ca-certificates

ok "audio, rete, permessi, dischi e font"

systemctl enable NetworkManager.service >/dev/null 2>&1 || true
as_user systemctl --user enable pipewire.service wireplumber.service >/dev/null 2>&1 || true
ok "servizi abilitati"

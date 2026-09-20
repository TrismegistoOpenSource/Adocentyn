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

# PipeWire non si tocca: i suoi servizi utente sono già attivi di default e si
# avviano al primo login. Da root, senza una sessione utente, "systemctl --user"
# fallirebbe comunque.
systemctl enable --now NetworkManager.service >/dev/null
ok "NetworkManager attivo"

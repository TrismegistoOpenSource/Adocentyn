#!/usr/bin/env bash
# Step 03 - Hyprland e il suo contorno, dai backports ufficiali.
set -euo pipefail
# shellcheck source=../lib/utils.sh
source "${ADOCENTYN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/utils.sh"

step "03 - Hyprland e Waybar"

# hyprland-qtutils serve ai dialoghi di sistema del compositore: senza, certi
# avvisi non vengono mostrati e finiscono solo nel log.
#
# libxkbregistry0 e libxkbcommon-x11-0 sembrano fuori posto qui, ma non lo sono:
# nascono dallo stesso sorgente di libxkbcommon0, che Hyprland tira dai
# backports, e dipendono dalla sua versione *esatta*. Lasciandoli a stable, apt
# dovrebbe retrocedere libxkbcommon0 e si ferma: Waybar li vuole per primo,
# kitty subito dopo.
apt_install_backports \
    hyprland hyprpaper hyprlock hypridle hyprpolkitagent \
    hyprland-qtutils xdg-desktop-portal-hyprland \
    libxkbregistry0 libxkbcommon-x11-0
ok "stack Hyprland dai backports"

apt_install \
    waybar wofi kitty dunst \
    wl-clipboard grim slurp brightnessctl playerctl \
    xdg-desktop-portal xdg-desktop-portal-gtk
ok "barra, launcher, terminale, notifiche e utilità"

# La config Lua esiste solo dalla 0.55: se un domani i backports regredissero,
# meglio accorgersene qui che davanti a uno schermo nero.
[ -f /usr/share/hypr/stubs/hl.meta.lua ] || \
    die "questa build di hyprland non espone l'API Lua: la configurazione di Adocentyn non funzionerebbe"

ok "hyprland $(dpkg-query -W -f='${Version}' hyprland), con API Lua"

#!/usr/bin/env bash
# Adocentyn - installazione di Hyprland su Debian 13 (Trixie) minima.
set -euo pipefail

ADOCENTYN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ADOCENTYN_ROOT
# shellcheck source=lib/utils.sh
source "$ADOCENTYN_ROOT/lib/utils.sh"

STEPS=(
    01_repos
    02_base
    03_hyprland
    04_apps
    05_claude_code
    06_dotfiles
)

usage() {
    cat <<EOF
Adocentyn $ADOCENTYN_VERSION - Hyprland su Debian 13 minima

  ./install.sh [step...]          (come root)

Senza argomenti esegue tutti gli step in ordine. Step disponibili:
$(printf '  %s\n' "${STEPS[@]}")

Variabili utili:
  ADOCENTYN_USER=<nome>   utente per cui configurare il desktop
EOF
}

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
esac

require_root
check_debian_trixie

if [ $# -gt 0 ]; then
    STEPS=("$@")
fi

printf '%s\n' "$C_BOLD"
cat <<'EOF'
   _       _                     _
  /_\   __| | ___   ___ ___ _ __| |_ _   _ _ __
 //_\\ / _` |/ _ \ / __/ _ \ '_ \ __| | | | '_ \
/  _  \ (_| | (_) | (_|  __/ | | | |_| |_| | | | |
\_/ \_/\__,_|\___/ \___\___|_| |_|\__|\__, |_| |_|
                                      |___/
EOF
printf '%s' "$C_OFF"
info "versione $ADOCENTYN_VERSION - utente: $(target_user) - home: $(target_home)"

for s in "${STEPS[@]}"; do
    script="$ADOCENTYN_ROOT/steps/${s}.sh"
    [ -f "$script" ] || die "step sconosciuto: $s"
    bash "$script"
done

step "Fatto"
info "riavvia, entra come $(target_user) sulla tty1 e Hyprland parte da solo."
info "Gli sfondi vanno in ~/.config/wallpaper/blu e ~/.config/wallpaper/mono."

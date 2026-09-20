#!/usr/bin/env bash
# Prova il ciclo di aggiornamento vero: funzione reale di lib/utils.sh,
# chezmoi reale, dotfiles reali del progetto.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

command -v chezmoi >/dev/null 2>&1 || { echo "serve chezmoi per questo test"; exit 1; }
rm -rf "$SANDBOX"; mkdir -p "$SANDBOX"

REPO="$SANDBOX/checkout"
HOME_TEST="$SANDBOX/home"
cp -R "$SRC" "$REPO"
cp "$SRC/.chezmoiroot" "$REPO/.chezmoiroot"
mkdir -p "$HOME_TEST/.config/chezmoi"
printf 'sourceDir = "%s"\n' "$REPO" > "$HOME_TEST/.config/chezmoi/chezmoi.toml"

source "$SRC/lib/utils.sh"

# Sul Mac non c'è runuser: qui "l'utente" siamo noi, con HOME nella sandbox.
as_user() { HOME="$HOME_TEST" "$@"; }

titolo() { printf '\n\033[1m%s\033[0m\n' "$*"; }
verifica() {
    if [ "$2" = "$3" ]; then printf '   OK   %s\n' "$1"
    else printf '   FALLITO %s\n      atteso: %s\n      ottenuto: %s\n' "$1" "$3" "$2"; ESITO=1; fi
}
ESITO=0

titolo "1) prima installazione"
chezmoi_apply_sicuro "$HOME_TEST" | sed 's/^/   /'
verifica "hyprland.lua creato" "$([ -f "$HOME_TEST/.config/hypr/hyprland.lua" ] && echo si || echo no)" "si"
verifica "tema blu creato"     "$([ -f "$HOME_TEST/.config/hypr/themes/blu.lua" ] && echo si || echo no)" "si"
verifica "script eseguibile"   "$([ -x "$HOME_TEST/.local/bin/adocentyn-theme" ] && echo si || echo no)" "si"
verifica "current-theme.css NON gestito (è generato)" \
    "$([ -f "$HOME_TEST/.config/waybar/current-theme.css" ] && echo si || echo no)" "no"

titolo "2) secondo giro identico: deve essere idempotente"
uscita="$(chezmoi_apply_sicuro "$HOME_TEST" 2>&1)"
verifica "nessuna modifica" "$(echo "$uscita" | grep -c 'già allineate')" "1"

titolo "3) arriva un aggiornamento dal repo"
printf '\n-- riga aggiunta da un aggiornamento\n' >> "$REPO/dotfiles/dot_config/hypr/decoration.lua"
printf -- '-- tema nuovo\n' > "$REPO/dotfiles/dot_config/hypr/themes/verde.lua"
chezmoi_apply_sicuro "$HOME_TEST" | sed 's/^/   /'
verifica "decoration.lua aggiornato" \
    "$(grep -c 'riga aggiunta da un aggiornamento' "$HOME_TEST/.config/hypr/decoration.lua")" "1"
verifica "tema nuovo arrivato" \
    "$([ -f "$HOME_TEST/.config/hypr/themes/verde.lua" ] && echo si || echo no)" "si"

titolo "4) l'utente modifica a mano una configurazione, poi arriva un aggiornamento"
printf -- '-- LA MIA MODIFICA PERSONALE\n' >> "$HOME_TEST/.config/hypr/keybindings.lua"
printf '\n-- aggiornamento del repo su keybindings\n' >> "$REPO/dotfiles/dot_config/hypr/keybindings.lua"
printf '\n-- aggiornamento del repo su userprefs\n' >> "$REPO/dotfiles/dot_config/hypr/userprefs.lua"
uscita="$(chezmoi_apply_sicuro "$HOME_TEST" 2>&1)"
echo "$uscita" | sed 's/^/   /'
verifica "la modifica dell'utente è ancora lì" \
    "$(grep -c 'LA MIA MODIFICA PERSONALE' "$HOME_TEST/.config/hypr/keybindings.lua")" "1"
verifica "keybindings NON sovrascritto dal repo" \
    "$(grep -c 'aggiornamento del repo su keybindings' "$HOME_TEST/.config/hypr/keybindings.lua")" "0"
verifica "userprefs invece è aggiornato" \
    "$(grep -c 'aggiornamento del repo su userprefs' "$HOME_TEST/.config/hypr/userprefs.lua")" "1"
verifica "il conflitto è stato segnalato" \
    "$(echo "$uscita" | grep -c 'modificati a mano')" "1"

titolo "5) i dati dell'utente non vengono mai toccati"
mkdir -p "$HOME_TEST/.config/adocentyn/wallpaper/blu"
printf 'la mia foto' > "$HOME_TEST/.config/adocentyn/wallpaper/blu/mio-sfondo.jpg"
printf 'dark\n' > "$HOME_TEST/.config/adocentyn/theme"
chezmoi_apply_sicuro "$HOME_TEST" >/dev/null 2>&1
verifica "sfondo dell'utente intatto" \
    "$(cat "$HOME_TEST/.config/adocentyn/wallpaper/blu/mio-sfondo.jpg")" "la mia foto"
verifica "scelta del tema intatta" "$(cat "$HOME_TEST/.config/adocentyn/theme")" "dark"

titolo "6) uno sfondo messo nel repository arriva sulla macchina"
printf 'finta immagine' > "$REPO/dotfiles/dot_config/adocentyn/wallpaper/dark/nuovo.png"
chezmoi_apply_sicuro "$HOME_TEST" | sed 's/^/   /'
verifica "lo sfondo del repo e' arrivato" \
    "$([ -f "$HOME_TEST/.config/adocentyn/wallpaper/dark/nuovo.png" ] && echo si || echo no)" "si"
verifica ".gitkeep NON viene copiato" \
    "$([ -f "$HOME_TEST/.config/adocentyn/wallpaper/dark/.gitkeep" ] && echo si || echo no)" "no"
verifica "lo sfondo locale dell'utente e' ancora li'" \
    "$(cat "$HOME_TEST/.config/adocentyn/wallpaper/blu/mio-sfondo.jpg" 2>/dev/null)" "la mia foto"

printf '\n'
[ "$ESITO" = 0 ] && printf '\033[0;32mTUTTI I TEST PASSATI\033[0m\n' || printf '\033[0;31mCI SONO FALLIMENTI\033[0m\n'
exit $ESITO

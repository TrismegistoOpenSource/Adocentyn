#!/usr/bin/env bash
# Step 06 - chezmoi e applicazione delle configurazioni.
set -euo pipefail
# shellcheck source=../lib/utils.sh
source "${ADOCENTYN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/utils.sh"

step "06 - configurazioni (chezmoi)"

USER_NAME="$(target_user)"
USER_GROUP="$(id -gn "$USER_NAME")"
USER_HOME="$(target_home)"
CHEZMOI_CONF_DIR="$USER_HOME/.config/chezmoi"
CHEZMOI_CONF="$CHEZMOI_CONF_DIR/chezmoi.toml"

# chezmoi non è in Debian stable (solo in sid): binario statico da upstream,
# in /usr/local/bin così lo vedono sia root sia l'utente.
if command -v chezmoi >/dev/null 2>&1; then
    skip "chezmoi già presente ($(chezmoi --version | head -1 | cut -d, -f1))"
else
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin >/dev/null
    command -v chezmoi >/dev/null 2>&1 || die "installazione di chezmoi fallita"
    ok "chezmoi installato in /usr/local/bin"
fi

# La sorgente di chezmoi è questo stesso checkout: .chezmoiroot gli dice di
# guardare dentro dotfiles/. Così "chezmoi update" fa git pull e applica, e le
# modifiche viaggiano fra le macchine senza una seconda copia da tenere allineata.
if [ ! -d "$ADOCENTYN_ROOT/.git" ]; then
    info "questo checkout non è un repository git: 'chezmoi update' non potrà aggiornarlo"
fi

# Il checkout deve appartenere all'utente, altrimenti non può né modificare le
# configurazioni né pubblicarle.
if [ "$(stat -c '%U' "$ADOCENTYN_ROOT")" != "$USER_NAME" ]; then
    chown -R "$USER_NAME:$USER_GROUP" "$ADOCENTYN_ROOT"
    ok "$ADOCENTYN_ROOT assegnato a $USER_NAME"
fi

if [ ! -f "$CHEZMOI_CONF" ]; then
    as_user mkdir -p "$CHEZMOI_CONF_DIR"
    as_user tee "$CHEZMOI_CONF" >/dev/null <<EOF
sourceDir = "$ADOCENTYN_ROOT"
EOF
    ok "chezmoi punta a $ADOCENTYN_ROOT"
elif grep -qF "$ADOCENTYN_ROOT" "$CHEZMOI_CONF"; then
    skip "chezmoi punta già a questo checkout"
else
    # File di configurazione dell'utente: si segnala, non si sovrascrive.
    info "$CHEZMOI_CONF punta altrove: lo lascio com'è"
    info "per usare questo checkout:  sourceDir = \"$ADOCENTYN_ROOT\""
fi

# Tutto ciò che è di Adocentyn sta qui sotto, niente sparso per ~/.config.
ADOCENTYN_CONF="$USER_HOME/.config/adocentyn"
as_user mkdir -p "$ADOCENTYN_CONF/wallpaper/blu" "$ADOCENTYN_CONF/wallpaper/mono"
if [ ! -f "$ADOCENTYN_CONF/theme" ]; then
    as_user tee "$ADOCENTYN_CONF/theme" >/dev/null <<<"blu"
    ok "tema iniziale: blu"
fi

chezmoi_apply_sicuro "$USER_HOME"

# current-theme.css è generato, quindi chezmoi lo ignora: senza, il CSS della
# barra non risolve l'import e Waybar parte senza colori.
THEME_NAME="$(cat "$ADOCENTYN_CONF/theme" 2>/dev/null || echo blu)"
as_user tee "$USER_HOME/.config/waybar/current-theme.css" >/dev/null \
    <<<"@import \"themes/${THEME_NAME}.css\";"

info "tema attivo: $THEME_NAME"

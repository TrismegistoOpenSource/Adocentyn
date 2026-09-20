#!/usr/bin/env bash
# Step 06 - chezmoi e applicazione delle configurazioni.
set -euo pipefail
# shellcheck source=../lib/utils.sh
source "${ADOCENTYN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/utils.sh"

step "06 - configurazioni (chezmoi)"

USER_NAME="$(target_user)"
USER_HOME="$(target_home)"
SOURCE_DIR="$USER_HOME/.local/share/chezmoi"

# chezmoi non è in Debian stable (solo in sid): binario statico da upstream,
# in /usr/local/bin così lo vedono sia root sia l'utente.
if command -v chezmoi >/dev/null 2>&1; then
    skip "chezmoi già presente ($(chezmoi --version | head -1))"
else
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin >/dev/null
    command -v chezmoi >/dev/null 2>&1 || die "installazione di chezmoi fallita"
    ok "chezmoi installato in /usr/local/bin"
fi

if [ -d "$SOURCE_DIR" ] && [ -n "$(ls -A "$SOURCE_DIR" 2>/dev/null)" ]; then
    # Qui dentro può esserci lavoro dell'utente: non si sovrascrive mai.
    skip "$SOURCE_DIR esiste già: lo lascio com'è"
    info "per applicare eventuali novità:  chezmoi apply"
else
    as_user mkdir -p "$SOURCE_DIR"
    as_user cp -R "$ADOCENTYN_ROOT/dotfiles/." "$SOURCE_DIR/"
    ok "dotfiles copiati in $SOURCE_DIR"

    if [ ! -d "$SOURCE_DIR/.git" ]; then
        as_user git init -q -b main "$SOURCE_DIR"
        as_user git -C "$SOURCE_DIR" add -A
        # Identità solo per questo commit: la configurazione git globale
        # dell'utente non si tocca.
        as_user git -C "$SOURCE_DIR" \
            -c user.name="$USER_NAME" \
            -c user.email="$USER_NAME@localhost" \
            commit -q -m "Configurazioni Adocentyn $ADOCENTYN_VERSION"
        ok "repository git dei dotfiles inizializzato"
    fi

    as_user chezmoi apply --force
    ok "configurazioni applicate"
fi

# Tutto ciò che è di Adocentyn sta qui sotto, niente sparso per ~/.config.
ADOCENTYN_CONF="$USER_HOME/.config/adocentyn"
as_user mkdir -p "$ADOCENTYN_CONF/wallpaper/blu" "$ADOCENTYN_CONF/wallpaper/mono"
if [ ! -f "$ADOCENTYN_CONF/theme" ]; then
    as_user tee "$ADOCENTYN_CONF/theme" >/dev/null <<<"blu"
fi
ok "cartelle degli sfondi pronte in $ADOCENTYN_CONF/wallpaper (vuote: le riempi tu)"

# current-theme.css è generato, quindi chezmoi lo ignora: senza, il CSS della
# barra non risolve l'import e Waybar parte senza colori.
THEME_NAME="$(cat "$ADOCENTYN_CONF/theme" 2>/dev/null || echo blu)"
as_user tee "$USER_HOME/.config/waybar/current-theme.css" >/dev/null \
    <<<"@import \"themes/${THEME_NAME}.css\";"
ok "tema attivo: $THEME_NAME"

info "i dotfiles sono un repo git in $SOURCE_DIR"
info "per versionarli su GitHub:  chezmoi cd  &&  git remote add origin <url>"

#!/usr/bin/env bash
# Funzioni comuni a bootstrap.sh, install.sh e agli step.

ADOCENTYN_VERSION="0.1.0"

C_CYAN=$'\033[0;36m'; C_GREEN=$'\033[0;32m'; C_YELLOW=$'\033[0;33m'
C_RED=$'\033[0;31m';  C_BOLD=$'\033[1m';     C_OFF=$'\033[0m'

step() { printf '\n%s==> %s%s\n' "$C_BOLD$C_CYAN" "$*" "$C_OFF"; }
info() { printf '    %s\n' "$*"; }
ok()   { printf '    %s✓%s %s\n' "$C_GREEN" "$C_OFF" "$*"; }
skip() { printf '    %s·%s %s\n' "$C_YELLOW" "$C_OFF" "$*"; }
err()  { printf '%sERRORE:%s %s\n' "$C_RED" "$C_OFF" "$*" >&2; }

die() { err "$*"; exit 1; }

require_root() {
    [ "$(id -u)" -eq 0 ] || die "serve root: rilancia con sudo"
}

# L'utente vero dietro al sudo. Gli step che toccano la home devono usare
# questo, non root, o i file finiscono in /root con i permessi sbagliati.
# Su una netinst appena installata si entra come root e sudo può non esserci
# affatto: in quel caso si cerca l'unico utente normale del sistema.
target_user() {
    if [ -n "${ADOCENTYN_USER:-}" ]; then
        id -u "$ADOCENTYN_USER" >/dev/null 2>&1 || die "l'utente '$ADOCENTYN_USER' non esiste"
        printf '%s' "$ADOCENTYN_USER"
        return
    fi

    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        printf '%s' "$SUDO_USER"
        return
    fi

    local candidates
    candidates="$(awk -F: '$3 >= 1000 && $3 < 60000 && $7 !~ /(nologin|false)$/ { print $1 }' /etc/passwd)"
    local count
    count="$(printf '%s\n' "$candidates" | grep -c . || true)"

    if [ "$count" -eq 1 ]; then
        printf '%s' "$candidates"
        return
    fi

    if [ "$count" -eq 0 ]; then
        die "nessun utente normale sul sistema: creane uno (adduser <nome>) e rilancia"
    fi

    err "più utenti possibili:"
    printf '%s\n' "$candidates" | sed 's/^/      /' >&2
    die "scegli tu:  ADOCENTYN_USER=<nome> ./install.sh"
}

target_home() {
    getent passwd "$(target_user)" | cut -d: -f6
}

# runuser e non sudo: su una netinst minima sudo può non essere installato.
as_user() {
    local u h
    u="$(target_user)"
    h="$(target_home)"
    runuser -u "$u" -- env HOME="$h" USER="$u" LOGNAME="$u" "$@"
}

apt_install() {
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

# I backports sono NotAutomatic: senza -t apt li ignora e il pacchetto
# "non esiste". Ogni pacchetto dello stack Hypr passa da qui.
apt_install_backports() {
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        -t trixie-backports "$@"
}

check_debian_trixie() {
    [ -r /etc/os-release ] || die "/etc/os-release illeggibile: non sembra un sistema Debian"
    # shellcheck disable=SC1091
    . /etc/os-release
    [ "${ID:-}" = "debian" ] || die "Adocentyn installa solo su Debian (trovato: ${ID:-sconosciuto})"
    [ "${VERSION_CODENAME:-}" = "trixie" ] || \
        die "serve Debian 13 (trixie), trovato '${VERSION_CODENAME:-sconosciuto}'"
}

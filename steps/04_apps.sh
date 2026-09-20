#!/usr/bin/env bash
# Step 04 - le poche applicazioni di tutti i giorni.
set -euo pipefail
# shellcheck source=../lib/utils.sh
source "${ADOCENTYN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/utils.sh"

step "04 - applicazioni"

# xed è dei repo Mint, Debian non lo pacchettizza: pluma è lo stesso fork di
# gedit da cui xed nasce, stessi menù e stesso peso.
apt_install nemo gnome-disk-utility pluma

ok "nemo, gnome-disk-utility, pluma"

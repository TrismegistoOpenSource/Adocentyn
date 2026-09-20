#!/usr/bin/env bash
# Step 04 - le poche applicazioni di tutti i giorni.
set -euo pipefail
# shellcheck source=../lib/utils.sh
source "${ADOCENTYN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/utils.sh"

step "04 - applicazioni"

# xed è dei repo Mint, Debian non lo pacchettizza: pluma è lo stesso fork di
# gedit da cui xed nasce, stessi menù e stesso peso.
#
# Il browser è firefox-esr: Debian in main pacchettizza solo quello, non il
# canale rapido. È lo stesso Firefox, su rilasci più lunghi.
apt_install nemo gnome-disk-utility pluma firefox-esr

ok "nemo, gnome-disk-utility, pluma, firefox-esr"

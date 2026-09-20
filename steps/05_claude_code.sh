#!/usr/bin/env bash
# Step 05 - Claude Code, installer ufficiale.
set -euo pipefail
# shellcheck source=../lib/utils.sh
source "${ADOCENTYN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/utils.sh"

step "05 - Claude Code"

# Va installato come utente, non come root: il binario sta in ~/.local/bin e si
# aggiorna da solo, quindi qui non serve nient'altro.
if [ -x "$(target_home)/.local/bin/claude" ]; then
    skip "già installato (si aggiorna da sé)"
else
    as_user sh -c 'curl -fsSL https://claude.ai/install.sh | bash'
    ok "installato in ~/.local/bin/claude"
    info "al primo uso serve il login: lancia 'claude' da utente normale"
fi

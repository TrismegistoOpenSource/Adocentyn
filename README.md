# Adocentyn

Installer di un desktop **Hyprland** semplice e stabile, a partire da una
**Debian 13 (Trixie)** netinst minima già installata.

> **Versione 0.1.0** — prima base funzionante: Hyprland con configurazione in
> **Lua**, Waybar, due temi, gestione degli sfondi per tema, le poche
> applicazioni indispensabili, Claude Code e i dotfiles versionati con chezmoi.

## Installazione

Da una Debian netinst appena installata, **come root** (su una minimale si entra
proprio così, e `sudo` spesso non c'è nemmeno):

```bash
apt install -y curl && curl -fsSL https://raw.githubusercontent.com/TrismegistoOpenSource/Adocentyn/main/bootstrap.sh | bash
```

Oppure a mano, se preferisci vedere il codice prima di eseguirlo:

```bash
apt install -y git && git clone https://github.com/TrismegistoOpenSource/Adocentyn.git && ./Adocentyn/install.sh
```

`bootstrap.sh` installa `git`, `curl` e i certificati, clona il repo in
`/opt/adocentyn` e lancia `install.sh`. È ripetibile: se il checkout c'è già,
lo aggiorna.

L'installer capisce da solo per quale utente configurare il desktop: se c'è un
solo utente normale usa quello, altrimenti lo si indica a mano.

```bash
ADOCENTYN_USER=nicolo ./install.sh
```

Ogni step è eseguibile da solo, utile quando si lavora su un pezzo alla volta:

```bash
sudo ./install.sh 03_hyprland
```

## Perché Debian e non Fedora

Fedora ha **ritirato l'intero stack Hyprland** dai repository ufficiali
(`hyprland`, `hyprpaper`, `hyprlock`, `hypridle` sono marcati `dead.package`,
motivo «Fails to install»). L'ultima Fedora con Hyprland ufficiale è la 42, già
fuori supporto: su Fedora 44 il compositore può arrivare solo da COPR personali
o da compilazione a mano.

Debian 13 con i **backports ufficiali** offre invece `hyprland 0.55.2` firmato,
insieme a `hyprpaper`, `hyprlock`, `hypridle`, `hyprpolkitagent` e
`xdg-desktop-portal-hyprland`. E 0.55 è esattamente la versione da cui Hyprland
accetta la **configurazione in Lua**, che è quella che questo progetto usa.

## Cosa installa

| Step | Contenuto |
|---|---|
| `01_repos` | componenti `contrib`/`non-free`/`non-free-firmware` + repository `trixie-backports` |
| `02_base` | PipeWire, NetworkManager, polkit, udisks, gvfs, font |
| `03_hyprland` | Hyprland, hyprpaper, hyprlock, hypridle, hyprpolkitagent, portal; Waybar, wofi, kitty, dunst, grim/slurp |
| `04_apps` | Nemo, GNOME Dischi, Pluma |
| `05_claude_code` | repository apt firmato di Anthropic, con verifica dell'impronta della chiave |
| `06_dotfiles` | chezmoi + applicazione delle configurazioni |

I pacchetti dei backports si installano con `-t trixie-backports`: senza quel
flag apt li ignora, perché i backports sono marcati `NotAutomatic`.

**Nota su `xed`**: non esiste in Debian, è un pacchetto dei repository Mint. Al
suo posto c'è **Pluma**, lo stesso fork di gedit da cui xed nasce. Si cambia in
una riga, in `steps/04_apps.sh`.

## Configurazione in Lua

Le config stanno in `~/.config/hypr/` e usano l'API `hl.*` di Hyprland ≥ 0.55:

```
hyprland.lua      punto di ingresso, autostart, variabili d'ambiente
monitors.lua      monitor
userprefs.lua     tastiera (layout it) e touchpad
decoration.lua    bordi, spaziature, sfocatura, animazioni
keybindings.lua   scorciatoie
windowrules.lua   regole delle finestre
themes/blu.lua    colori del tema blu
themes/mono.lua   colori del tema bianco e nero
```

Lo step 03 si ferma se la build installata non espone `hl.meta.lua`: meglio un
errore chiaro dell'installer che uno schermo nero al riavvio.

## Temi e sfondi

Due temi: **blu** (blu vivo) e **mono** (bianco e nero). Il tema attivo è un
nome scritto in `~/.config/adocentyn/theme`; Hyprland lo legge all'avvio e
Waybar lo prende da `current-theme.css`.

Gli sfondi si leggono da una cartella per tema, che l'installer crea vuote:

```
~/.config/wallpaper/blu/
~/.config/wallpaper/mono/
```

Mettici le immagini che vuoi (`jpg`, `png`, `webp`). `adocentyn-wallpaper` ne
pesca una a caso da quella del tema attivo. Se la cartella è vuota non succede
nulla e non compaiono errori.

## Scorciatoie

`M` = tasto SUPER (Windows).

```
programmi   M+T terminale · M+E Nemo · M+A menù · M+N editor · M+D dischi
finestre    M+Q chiudi · M+W flottante · M+F schermo intero · M+P pseudo
            M+J dividi · M+frecce fuoco · M+tasto sx sposta · M+tasto dx ridimensiona
spazi       M+1..9 vai · M+SHIFT+1..9 sposta la finestra · M+rotella scorri
            M+S scratchpad · M+SHIFT+S manda allo scratchpad
tema        M+SHIFT+T cambia tema · M+SHIFT+W cambia sfondo
sistema     M+L blocca · M+SHIFT+P schermata di una zona · M+SHIFT+Q esci
```

## Dotfiles con chezmoi

chezmoi non è nei repository Debian stable (sta solo in sid), quindi lo step 06
installa il binario ufficiale in `/usr/local/bin`.

Le configurazioni diventano un repository git in `~/.local/share/chezmoi`, con
un primo commit già fatto. Per versionarle su GitHub:

```bash
chezmoi cd
git remote add origin <url-del-tuo-repo>
git push -u origin main
```

Da lì in avanti: `chezmoi edit ~/.config/hypr/keybindings.lua`, poi
`chezmoi apply`, poi commit. Se `~/.local/share/chezmoi` esiste già, lo step 06
**non lo tocca**: le modifiche locali non vengono mai sovrascritte.

## Avvio della sessione

Nessun display manager: si entra sulla console, e su **tty1** parte Hyprland da
solo (`~/.bash_profile`). Sulle altre console resta la shell, che è la via di
fuga quando il desktop non parte.

## Sulla fascia di avvisi di Hyprland

La striscia che Hyprland mostra in alto appena installato è l'avviso di
configurazione autogenerata: compare solo quando Hyprland non trova una propria
config e se ne scrive una. Qui la configurazione è già al suo posto, quindi non
si presenta. In più `hyprland.lua` spegne esplicitamente logo, splash e gli
avvisi di aggiornamento e donazione (`ecosystem.no_update_news`,
`ecosystem.no_donation_nag`).

## Build

```bash
sourcecode/scripts/build.sh
```

Prepara in `build/` il pacchetto pronto all'uso: gli script, i dotfiles e il
`bootstrap.sh`.

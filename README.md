# Adocentyn

Installer di un desktop **Hyprland** semplice e stabile, a partire da una
**Debian 13 (Trixie)** netinst minima già installata.

> **Versione 0.1.0** — prima base funzionante: Hyprland con configurazione in
> **Lua**, Waybar, due temi, gestione degli sfondi per tema, le poche
> applicazioni indispensabili, Claude Code e i dotfiles versionati con chezmoi.

## Installazione

Su una netinst minima **non c'è né git né curl**: il primo comando serve a
procurarsi git. Da fare **come root** (su una minimale si entra proprio così, e
`sudo` spesso non è nemmeno installato):

```bash
apt update && apt install -y git
```

```bash
git clone https://github.com/TrismegistoOpenSource/Adocentyn.git /opt/adocentyn
```

```bash
cd /opt/adocentyn && ./install.sh
```

Per aggiornare il progetto più avanti, senza riclonare:

```bash
git -C /opt/adocentyn pull && /opt/adocentyn/install.sh
```

L'installer capisce da solo per quale utente configurare il desktop: se c'è un
solo utente normale usa quello, altrimenti lo si indica a mano.

```bash
ADOCENTYN_USER=nicolo ./install.sh
```

### Se `apt install git` fallisce

Vuol dire che l'installazione è stata fatta **senza mirror di rete**: il sistema
conosce solo il CD. Lo step `01_repos` sa rimediare da solo, ma non può girare
prima di git. In quel caso si scrivono i repository a mano, una volta sola:

```bash
cat > /etc/apt/sources.list.d/debian.sources <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
```

```bash
sed -i 's|^deb cdrom:|# deb cdrom:|' /etc/apt/sources.list; apt update && apt install -y git
```

### Scorciatoia con curl

Se `curl` c'è già, `bootstrap.sh` fa da solo i tre passaggi (installa git, clona
in `/opt/adocentyn`, lancia l'installer) e sa scrivere i repository se mancano:

```bash
curl -fsSL https://raw.githubusercontent.com/TrismegistoOpenSource/Adocentyn/main/bootstrap.sh | bash
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
| `05_claude_code` | Claude Code con l'installer ufficiale, in `~/.local/bin` del tuo utente |
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
themes/*.lua      colori dei bordi, uno per tema
```

Lo step 03 si ferma se la build installata non espone `hl.meta.lua`: meglio un
errore chiaro dell'installer che uno schermo nero al riavvio.

## Temi e sfondi

Tre temi:

| Tema | Aspetto |
|---|---|
| `dark` | scuro neutro |
| `blu` | scuro con tonalità blu |
| `white` | chiaro |

`SUPER+SHIFT+T` passa al successivo, in tondo. Per andare diretto a uno:
`adocentyn-theme white`.

Tutto ciò che appartiene ad Adocentyn sta in **una cartella sola**, senza
spargere niente in giro per `~/.config`:

```
~/.config/adocentyn/
├── theme                 nome del tema attivo, una riga
└── wallpaper/
    ├── blu/
    ├── dark/
    └── white/
```

### Dove mettere gli sfondi

Due posti, a seconda di cosa vuoi:

**Nel repository**, in `dotfiles/dot_config/adocentyn/wallpaper/<tema>/`: così
sono versionati e `chezmoi update` li porta su tutte le tue macchine. È il posto
giusto per gli sfondi che vuoi ritrovare ovunque.

**Direttamente in `~/.config/adocentyn/wallpaper/<tema>/`** sulla macchina: chezmoi
non li tocca e non li cancella, restano locali a quel computer.

Formati riconosciuti: `jpg`, `jpeg`, `png`, `webp`. Le immagini sono file
binari: se ne metti molte e pesanti nel repository, il repository cresce in
proporzione e ogni macchina se le scarica tutte.

Le uniche eccezioni sono i file che devono stare dove il programma li cerca:
`~/.config/hypr/` per Hyprland e `~/.config/waybar/` per la barra. Quelli non
sono spostabili, ma sono le posizioni standard: nessun programma va a cercare
altrove.

Mettici le immagini che vuoi (`jpg`, `png`, `webp`). `adocentyn-wallpaper` ne
pesca una a caso dalla cartella del tema attivo. Se la cartella è vuota non
succede nulla e non compaiono errori.

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

## Aggiornare, non reinstallare

Rilanciare `install.sh` su una macchina già configurata **è** l'aggiornamento:
si comporta come un `apt upgrade` del solo Adocentyn, senza riscaricare ciò che
c'è già e senza toccare quello che hai personalizzato.

```bash
chezmoi update                    # da utente: git pull del repo + applica
sudo /opt/adocentyn/install.sh    # da root: pacchetti e sistema
```

`chezmoi update` aggiorna **l'intero checkout**, quindi anche gli script di
installazione: prima si aggiorna il repo, poi si rilancia l'installer nuovo.

Cosa succede a ogni pezzo quando rilanci:

| Pezzo | Comportamento |
|---|---|
| Repository apt | già configurati → saltati |
| Pacchetti | `apt` installa solo ciò che manca e aggiorna ciò che è vecchio |
| Claude Code | già presente → saltato (si aggiorna da solo) |
| chezmoi | già installato → saltato |
| Configurazioni | applicate solo le differenze reali |
| **File che hai modificato a mano** | **lasciati intatti**, con l'elenco a schermo |
| Sfondi, tema scelto | mai toccati |

Se hai modificato a mano un file gestito, l'installer non lo sovrascrive e ti
dice come procedere:

```bash
chezmoi merge ~/.config/hypr/keybindings.lua    # unisci le tue e le nuove
chezmoi re-add ~/.config/hypr/keybindings.lua   # tieni le tue, aggiorna il repo
chezmoi apply --force ~/.config/hypr/keybindings.lua   # butta le tue
```

Questo comportamento è coperto da un test:

```bash
./tests/test-aggiornamento.sh
```

## Dotfiles con chezmoi

chezmoi non è nei repository Debian stable (sta solo in sid), quindi lo step 06
installa il binario ufficiale in `/usr/local/bin`.

**La sorgente di chezmoi è questo stesso repository**: il file `.chezmoiroot`
gli dice di guardare dentro `dotfiles/`. Non esiste una seconda copia da tenere
allineata, e il checkout viene assegnato al tuo utente così puoi modificarlo e
pubblicarlo.

Il ciclo di lavoro è:

```bash
chezmoi edit ~/.config/hypr/keybindings.lua   # modifica la sorgente nel repo
chezmoi apply                                 # prova la modifica sul sistema
chezmoi cd && git commit -am "..." && git push
```

### Più macchine

Le altre macchine prendono le modifiche con un comando solo:

```bash
chezmoi update
```

Fa `git pull` e applica, sempre rispettando i file modificati in locale su
quella macchina. Se l'aggiornamento tocca anche gli script di installazione
(pacchetti nuovi, step nuovi), dopo si rilancia `sudo install.sh`.

> Le configurazioni sono per ora **uguali su tutte le macchine**. Quando servirà
> differenziarle (monitor diversi, portatile contro fisso), chezmoi lo fa con i
> template: è il passo successivo, non serve ancora.

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

Crea `build/adocentyn-<versione>.tar.gz` da quanto è committato in `HEAD`.
Serve per distribuire una versione; per l'uso normale si clona il repository,
perché `chezmoi update` ha bisogno che la sorgente sia un checkout git.

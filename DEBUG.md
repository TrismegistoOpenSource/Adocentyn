# Debug in corso — lo sfondo non compare

> File di passaggio fra due macchine. È **temporaneo**: quando il problema è
> risolto va cancellato, e quello che si è imparato va in `README.md` o nel
> `PROBLEMI-NOTI.md` del workspace.
>
> Scritto il 20/09/2026, dopo la prima installazione su ferro vero.

## Dove siamo

Prima installazione su una Debian 13 minima, riuscita fino in fondo. Hyprland
parte, Waybar c'è. **Manca solo lo sfondo.**

Macchina: `atlante@geekom`, checkout in `~/Adocentyn` (non in `/opt`).
Hyprland `0.55.2+ds-1~bpo13+1`, hyprpaper `0.8.4-1~bpo13+1`, entrambi dai
backports ufficiali.

## Cosa è già stato sistemato durante questa installazione

1. **`libxkbregistry0` e `libxkbcommon-x11-0` dovevano venire dai backports.**
   Nascono dallo stesso sorgente di `libxkbcommon0`, che Hyprland tira dai
   backports, e ne richiedono la versione esatta: presi da stable, apt doveva
   retrocedere `libxkbcommon0` e si fermava. Bloccava Waybar, e subito dopo
   avrebbe bloccato kitty. Corretto in `steps/03_hyprland.sh`.

2. **L'avvio deve passare da `start-hyprland`, non dal binario `Hyprland`.**
   Dalla 0.55 il compositore avvisa: *«Hyprland is being launched without
   start-hyprland. This is highly advised against.»* `start-hyprland` lo
   sorveglia con un watchdog. Corretto in `dotfiles/dot_bash_profile`.

## Il problema aperto

Lo sfondo non viene applicato. Non è ancora stato diagnosticato sulla macchina:
quanto segue è un **sospetto**, non un fatto.

**Sospetto principale:** hyprpaper 0.8.4 ha cambiato meccanismo di IPC. Nel
sorgente upstream al tag `v0.8.4` c'è `src/ipc/IPC.cpp`, che usa un protocollo
Wayland **a oggetti** (`CHyprpaperWallpaperObject`, `setFitMode`,
`sendActiveWallpaper`), mentre `adocentyn-wallpaper` usa i comandi testuali
`hyprctl hyprpaper preload` e `hyprctl hyprpaper wallpaper`, che erano
l'interfaccia delle versioni ≤ 0.7. Non è stato verificato se quei comandi
siano ancora accettati.

**Seconda pista:** Debian abilita un servizio utente `hyprpaper.service`
agganciato a `graphical-session.target` (si vede nel log di installazione:
`Created symlink '/etc/systemd/user/graphical-session.target.wants/hyprpaper.service'`).
Noi però lanciamo hyprpaper dall'autostart di Hyprland
(`dotfiles/dot_config/hypr/hyprland.lua`), e la sessione non è gestita da
systemd né da uwsm. Quindi: o il servizio non parte mai, o partono due istanze
che si pestano i piedi.

## Da fare per primo: raccogliere i fatti

Dentro Hyprland, terminale con `SUPER+T`:

```bash
echo "--- tema ---"; cat ~/.config/adocentyn/theme; echo "--- sfondi presenti ---"; ls ~/.config/adocentyn/wallpaper/*/ ; echo "--- hyprpaper in esecuzione? ---"; pgrep -a hyprpaper || echo "NON in esecuzione"; echo "--- cosa dice lo script ---"; adocentyn-wallpaper; echo "--- IPC ---"; hyprctl hyprpaper listloaded
```

E la prova diretta, che separa "è lo script mio" da "è l'IPC che è cambiato":

```bash
hyprctl hyprpaper preload ~/.config/adocentyn/wallpaper/blu/astronaut2.png && hyprctl hyprpaper wallpaper ",$HOME/.config/adocentyn/wallpaper/blu/astronaut2.png"
```

## Come leggere i risultati

| Cosa si osserva | Cosa significa | Dove intervenire |
|---|---|---|
| le cartelle degli sfondi sono vuote | chezmoi non ha applicato le immagini | `steps/06_dotfiles.sh`, e verificare `.chezmoiignore` |
| `hyprpaper` non è in esecuzione | l'autostart non lo avvia | `dotfiles/dot_config/hypr/hyprland.lua`, blocco `hl.on("hyprland.start", ...)` |
| è in esecuzione ma l'IPC dà errore | protocollo cambiato nella 0.8.4 | riscrivere `adocentyn-wallpaper`: scrivere `preload`/`wallpaper` in `~/.config/hypr/hyprpaper.conf` e riavviare hyprpaper, invece di usare `hyprctl` |
| il comando manuale funziona | il difetto è nel mio script, non nell'IPC | `dotfiles/dot_local/bin/executable_adocentyn-wallpaper` |
| due processi hyprpaper | doppio avvio, autostart + servizio systemd | disabilitare il servizio utente, oppure togliere l'autostart e usare il servizio |

## Contesto del progetto che serve per intervenire

**La sorgente di chezmoi è il checkout stesso.** `.chezmoiroot` contiene
`dotfiles`, quindi chezmoi legge `~/Adocentyn/dotfiles/`. Non esiste una
seconda copia: si modifica il repo e si applica.

```bash
chezmoi edit ~/.local/bin/adocentyn-wallpaper   # apre il file nel repo
chezmoi apply                                   # lo mette in opera
chezmoi update                                  # git pull + apply
```

**I file coinvolti nello sfondo:**

```
dotfiles/dot_local/bin/executable_adocentyn-wallpaper   lo script
dotfiles/dot_config/hypr/hyprpaper.conf                 config del demone
dotfiles/dot_config/hypr/hyprland.lua                   autostart di hyprpaper
dotfiles/dot_config/adocentyn/wallpaper-default.conf    quale sfondo per tema
dotfiles/dot_config/adocentyn/wallpaper/<tema>/          le immagini
```

**Come funziona adesso:** il tema attivo è un nome in
`~/.config/adocentyn/theme` (`blu`, `dark`, `white`). `adocentyn-wallpaper`
senza argomenti mette il predefinito del tema, con `--random` ne pesca uno a
caso. Il nome nel file dei default è **senza estensione**, cercata poi fra jpg,
jpeg, png e webp. Se il file non si trova si ripiega su uno a caso.

**Regole da rispettare** (stanno anche nel `CLAUDE.md` del workspace):

- Niente `git push` senza che l'utente lo chieda **in quel momento**.
- Non sovrascrivere file che l'utente ha modificato a mano: `chezmoi status`
  con la prima colonna `M` li distingue, e `chezmoi_apply_sicuro` in
  `lib/utils.sh` li salta apposta. Mai `chezmoi apply --force` in automatico.
- Nomi di file: solo minuscole, numeri e trattini. Attenzione alla **virgola**,
  che romperebbe `hyprctl hyprpaper wallpaper ",$file"`.
- Nessun trailer `Co-Authored-By` e nessuna menzione di Claude nei commit.

**Prima di dichiarare risolto:** `./tests/test-aggiornamento.sh` deve passare,
e l'installer va rilanciato (`sudo ./install.sh`) per verificare che sia ancora
idempotente.

## Fuori dallo sfondo, cosa resta da verificare

Nessuno di questi punti è stato ancora guardato su ferro:

- Waybar mostra davvero tutti i moduli (rete, audio, batteria, tray)?
- `SUPER+SHIFT+T` gira fra i tre temi e Waybar cambia colore?
- L'audio funziona (PipeWire parte al login)?
- `SUPER+L` blocca lo schermo con hyprlock?
- Le schermate con `SUPER+SHIFT+P` (grim + slurp) finiscono negli appunti?
- Il portal funziona (condivisione schermo, scelta file)?

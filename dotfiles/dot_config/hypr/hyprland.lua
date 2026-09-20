-- hyprland.lua - configurazione Adocentyn
-- API Lua di Hyprland >= 0.55: https://wiki.hypr.land/Configuring/Start/

require("monitors")
require("userprefs")
require("decoration")
require("keybindings")
require("windowrules")

-- Il tema attivo è solo un nome scritto in un file: qui si carica il modulo
-- corrispondente, che sovrascrive i colori del bordo.
local function active_theme()
    local path = os.getenv("HOME") .. "/.config/adocentyn/theme"
    local f = io.open(path, "r")
    if not f then return "blu" end
    local name = (f:read("l") or ""):gsub("%s", "")
    f:close()
    if name == "" then return "blu" end
    return name
end

-- pcall: un nome di tema scritto male non deve lasciare il desktop senza config
if not pcall(require, "themes." .. active_theme()) then
    require("themes.blu")
end

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("dunst")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
    hl.exec_cmd("adocentyn-wallpaper")
end)

hl.env("XCURSOR_SIZE",         "24")
hl.env("HYPRCURSOR_SIZE",      "24")
hl.env("XDG_CURRENT_DESKTOP",  "Hyprland")
hl.env("XDG_SESSION_TYPE",     "wayland")
hl.env("XDG_SESSION_DESKTOP",  "Hyprland")
hl.env("GDK_BACKEND",          "wayland,x11,*")
hl.env("QT_QPA_PLATFORM",      "wayland;xcb")
hl.env("MOZ_ENABLE_WAYLAND",   "1")

hl.config({
    misc = {
        -- Niente mascotte, niente logo, niente splash: lo sfondo lo mettiamo noi.
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },

    -- Toglie la fascia di avvisi in alto (novità di versione e richiesta di
    -- donazione) che Hyprland mostra appena installato.
    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },
})

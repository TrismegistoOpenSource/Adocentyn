-- keybindings.lua - M = SUPER (tasto Windows).
local M = "SUPER"

local terminal    = "kitty"
local fileManager = "nemo"
local menu        = "wofi --show drun"
local editor      = "pluma"

-- Programmi
hl.bind(M .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(M .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(M .. " + A", hl.dsp.exec_cmd(menu))
hl.bind(M .. " + N", hl.dsp.exec_cmd(editor))
hl.bind(M .. " + D", hl.dsp.exec_cmd("gnome-disks"))

-- Finestre
hl.bind(M .. " + Q",         hl.dsp.window.close())
hl.bind(M .. " + W",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(M .. " + F",         hl.dsp.window.fullscreen())
hl.bind(M .. " + P",         hl.dsp.window.pseudo())
hl.bind(M .. " + J",         hl.dsp.layout("togglesplit"))
hl.bind(M .. " + left",      hl.dsp.focus({ direction = "left" }))
hl.bind(M .. " + right",     hl.dsp.focus({ direction = "right" }))
hl.bind(M .. " + up",        hl.dsp.focus({ direction = "up" }))
hl.bind(M .. " + down",      hl.dsp.focus({ direction = "down" }))
hl.bind(M .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(M .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Spazi di lavoro
for i = 1, 10 do
    local key = i % 10
    hl.bind(M .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(M .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(M .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(M .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(M .. " + S",          hl.dsp.workspace.toggle_special("magic"))
hl.bind(M .. " + SHIFT + S",  hl.dsp.window.move({ workspace = "special:magic" }))

-- Tema e sfondo
hl.bind(M .. " + SHIFT + T", hl.dsp.exec_cmd("adocentyn-theme"))
hl.bind(M .. " + SHIFT + W", hl.dsp.exec_cmd("adocentyn-wallpaper"))

-- Schermate e blocco
hl.bind(M .. " + SHIFT + P", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind(M .. " + L",         hl.dsp.exec_cmd("hyprlock"))

-- Uscita
hl.bind(M .. " + SHIFT + Q", hl.dsp.exec_cmd("hyprctl dispatch exit"))

-- Tasti multimediali
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

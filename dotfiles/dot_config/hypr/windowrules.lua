-- windowrules.lua
hl.window_rule({
    name  = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Senza questa, trascinare finestre XWayland dà problemi di messa a fuoco.
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name  = "dischi-flottante",
    match = { class = "^(org.gnome.DiskUtility)$" },
    float = true,
})

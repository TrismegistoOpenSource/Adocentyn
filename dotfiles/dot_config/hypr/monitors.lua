-- monitors.lua - un monitor in automatico.
-- Per aggiungerne altri: un blocco hl.monitor() per ciascuno, con output preso
-- da `hyprctl monitors`.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

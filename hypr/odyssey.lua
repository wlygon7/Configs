-- Managed by Odyssey host integration v3
hl.layer_rule({
    name = "odyssey-liquid-glass",
    match = { namespace = "^odyssey:(island|notes):glass$" },
    blur = true,
    ignore_alpha = 0.02,
})
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start odyssey.service")
    hl.exec_cmd("bash -c \"pgrep -u $USER -x wl-paste >/dev/null || wl-paste --watch cliphist store &\"")
end)
-- BEGIN ODYSSEY MANAGED SHORTCUTS
hl.bind("SUPER + A", hl.dsp.exec_cmd("'/home/wlygon7/.local/bin/odyssey' ipc launcher toggle"), { description = "Open application launcher" })
hl.bind("SUPER + CTRL + A", hl.dsp.exec_cmd("'/home/wlygon7/.local/bin/odyssey' ipc command-launcher toggle"), { description = "Open command launcher" })
hl.bind("SUPER + V", hl.dsp.exec_cmd("'/home/wlygon7/.local/bin/odyssey' ipc clipboard toggle"), { description = "Open clipboard history" })
hl.bind("SUPER + comma", hl.dsp.exec_cmd("'/home/wlygon7/.local/bin/odyssey' ipc settings open"), { description = "Open Odyssey settings" })
hl.bind("SUPER + N", hl.dsp.exec_cmd("'/home/wlygon7/.local/bin/odyssey' ipc notifications toggle"), { description = "Open notifications" })
hl.bind("SUPER + Y", hl.dsp.exec_cmd("'/home/wlygon7/.local/bin/odyssey' ipc insights wallpaper"), { description = "Open wallpaper library" })
hl.bind("SUPER + space", hl.dsp.exec_cmd("'/home/wlygon7/.local/bin/odyssey' ipc control-center toggle"), { description = "Open Control Center" })
hl.bind("SUPER + ALT + L", hl.dsp.exec_cmd("'/home/wlygon7/.local/bin/odyssey' ipc session lock"), { description = "Lock session" })
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("'/home/wlygon7/.local/bin/odyssey' ipc capture screenshot region both"), { description = "Capture and save a region screenshot" })
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("'/home/wlygon7/.local/bin/odyssey' ipc capture record region"), { description = "Record a screen region" })
hl.bind("SUPER + ALT + N", hl.dsp.exec_cmd("'/home/wlygon7/.local/bin/odyssey' ipc notes toggle"), { description = "Toggle Notes" })
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("'/home/wlygon7/.local/bin/odyssey' ipc notes create"), { description = "Create a new note" })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("'/home/wlygon7/.local/bin/odyssey' ipc audio increment 3"), { locked = true, repeating = true, description = "Raise volume" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("'/home/wlygon7/.local/bin/odyssey' ipc audio decrement 3"), { locked = true, repeating = true, description = "Lower volume" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("'/home/wlygon7/.local/bin/odyssey' ipc audio mute"), { locked = true, description = "Toggle audio mute" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("'/home/wlygon7/.local/bin/odyssey' ipc audio micmute"), { locked = true, description = "Toggle microphone mute" })
-- END ODYSSEY MANAGED SHORTCUTS

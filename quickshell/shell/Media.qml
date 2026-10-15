pragma Singleton

import Quickshell
import Quickshell.Services.Mpris

// Picks the one player the bar should show
Singleton {
    // mpvpaper can expose itself over MPRIS; never treat the wallpaper as music
    readonly property var players: Mpris.players.values.filter(p => !p.dbusName.toLowerCase().includes("mpv"))

    readonly property MprisPlayer player: players.find(p => p.isPlaying)
        ?? players.find(p => p.dbusName.toLowerCase().includes("spotify"))
        ?? players[0]
        ?? null

    readonly property bool playing: player?.isPlaying ?? false

    // Browsers keep paused tabs around forever, so only a music app stays visible while paused
    readonly property bool visible: player !== null && player.trackTitle !== ""
        && (playing || player.dbusName.toLowerCase().includes("spotify"))

    function time(seconds) {
        const s = Math.max(0, Math.floor(seconds))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }
}

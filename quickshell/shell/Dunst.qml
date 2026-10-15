pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Everything the shell knows about dunst: do-not-disturb, the queue while paused ("waiting"),
// and the history list the notification centre shows.
Singleton {
    id: dunst

    property bool paused: false
    property int waiting: 0
    // Newest first: { id, app, summary, body, icon, urgency, age } with age in seconds
    property var history: []
    readonly property int unread: history.filter(n => n.id > seen.lastId).length
    // Poll faster while the notification centre is open
    property bool watching: false

    function refresh() {
        if (!probe.running) probe.running = true
    }

    function toggleDnd() {
        paused = !paused
        Quickshell.execDetached(["dunstctl", "set-paused", "toggle"])
        settle.restart()
    }

    function showLast() {
        Quickshell.execDetached(["dunstctl", "history-pop"])
        settle.restart()
    }

    function closeAll() {
        Quickshell.execDetached(["dunstctl", "close-all"])
    }

    function markRead() {
        if (history.length > 0) seen.lastId = Math.max(seen.lastId, history[0].id)
    }

    // Shows a past notification again, so its actions can be clicked
    function show(id) {
        history = history.filter(n => n.id !== id)
        Quickshell.execDetached(["dunstctl", "history-pop", String(id)])
        settle.restart()
    }

    function remove(id) {
        history = history.filter(n => n.id !== id)
        Quickshell.execDetached(["dunstctl", "history-rm", String(id)])
    }

    function clear() {
        history = []
        Quickshell.execDetached(["dunstctl", "history-clear"])
    }

    function age(seconds) {
        if (seconds < 60) return "now"
        if (seconds < 3600) return Math.floor(seconds / 60) + "m"
        if (seconds < 86400) return Math.floor(seconds / 3600) + "h"
        return Math.floor(seconds / 86400) + "d"
    }

    PersistentProperties {
        id: seen
        reloadableId: "dunstSeen"
        property int lastId: 0
    }

    Process {
        id: probe
        // dunst timestamps are microseconds of monotonic time, which matches /proc/uptime
        command: ["sh", "-c", "dunstctl is-paused; dunstctl count waiting; cut -d' ' -f1 /proc/uptime; dunstctl history"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                if (lines.length < 4) return
                dunst.paused = lines[0].trim() === "true"
                dunst.waiting = parseInt(lines[1]) || 0
                const uptime = parseFloat(lines[2]) || 0
                try {
                    const entries = JSON.parse(lines.slice(3).join("\n")).data[0] ?? []
                    dunst.history = entries.map(n => ({
                        id: n.id.data,
                        app: n.appname.data,
                        summary: n.summary.data,
                        body: n.body.data,
                        icon: n.icon_path.data,
                        urgency: n.urgency.data,
                        age: Math.max(0, uptime - n.timestamp.data / 1e6)
                    }))
                } catch (e) {
                    // dunst not running yet; keep what we had
                }
            }
        }
    }

    Timer { id: settle; interval: 300; onTriggered: dunst.refresh() }
    Timer {
        interval: dunst.watching ? 1500 : 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: dunst.refresh()
    }
}

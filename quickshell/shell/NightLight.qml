pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Night light via hyprsunset. The schedule lives in ~/.config/hypr/hyprsunset.conf (warm from
// 21:00 to 07:00); the toggle overrides it until the next scheduled change, like hyprsunset does.
Singleton {
    id: night

    readonly property int temperature: 4500
    property bool available: false
    property bool enabled: scheduled(new Date())
    property bool lastScheduled: scheduled(new Date())

    function scheduled(date) {
        const hour = date.getHours()
        return hour >= 21 || hour < 7
    }

    function toggle() {
        if (!available) return
        enabled = !enabled
        Quickshell.execDetached(["hyprctl", "hyprsunset", ...(enabled ? ["temperature", String(temperature)] : ["identity"])])
    }

    // Follow the schedule when it flips
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            const now = night.scheduled(new Date())
            if (now === night.lastScheduled) return
            night.lastScheduled = now
            night.enabled = now
        }
    }

    // hyprsunset may get installed while the shell is running, so keep checking until it is
    Process {
        id: check
        command: ["sh", "-c", "command -v hyprsunset"]
        running: true
        onExited: code => night.available = code === 0
    }
    Timer { interval: 30000; running: !night.available; repeat: true; onTriggered: check.running = true }
}

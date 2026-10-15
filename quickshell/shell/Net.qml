pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Primary connection from NetworkManager. Event-driven via `nmcli monitor`, with a slow fallback poll.
Singleton {
    id: net

    property string kind: "none" // wired | wifi | none
    property string name: ""
    property int strength: 0
    property bool wifiEnabled: false

    readonly property string icon: kind === "wired" ? Icons.ethernet
        : kind === "wifi" ? (strength > 75 ? Icons.wifi4 : strength > 50 ? Icons.wifi3 : strength > 25 ? Icons.wifi2 : Icons.wifi1)
        : Icons.offline

    function refresh() {
        if (!probe.running) probe.running = true
    }

    function setWifi(enabled) {
        wifiEnabled = enabled
        Quickshell.execDetached(["nmcli", "radio", "wifi", enabled ? "on" : "off"])
    }

    Process {
        id: probe
        // First line is the Wi-Fi radio state, second the primary connection
        command: ["sh", "-c", `
            nmcli radio wifi
            nmcli -t -f TYPE,STATE,CONNECTION device | while IFS=: read -r type state conn; do
                [ "$state" = connected ] || continue
                case $type in
                    ethernet) echo "wired|$conn"; exit ;;
                    wifi) echo "wifi|$conn|$(nmcli -t -f ACTIVE,SIGNAL dev wifi list --rescan no | awk -F: '$1 == "yes" { print $2; exit }')"; exit ;;
                esac
            done`]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                net.wifiEnabled = lines[0] === "enabled"
                const parts = (lines[1] ?? "").split("|")
                net.kind = parts[0] === "wired" || parts[0] === "wifi" ? parts[0] : "none"
                net.name = parts[1] ?? ""
                net.strength = parseInt(parts[2]) || 0
            }
        }
    }

    Process {
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser { onRead: debounce.restart() }
    }

    Timer { id: debounce; interval: 600; onTriggered: net.refresh() }
    Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: net.refresh() }
}

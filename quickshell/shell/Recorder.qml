pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Screen recording with gpu-screen-recorder (records desktop audio too).
// Saves to ~/Videos/Recordings; the "saved" notification opens the video when clicked.
Singleton {
    id: recorder

    readonly property bool recording: proc.running
    readonly property string dir: Quickshell.env("HOME") + "/Videos/Recordings"
    property string file: ""
    property int elapsed: 0

    readonly property string time: Math.floor(elapsed / 60) + ":" + String(elapsed % 60).padStart(2, "0")

    function toggleRegion() {
        recording ? stop() : start("region")
    }

    function toggleScreen() {
        recording ? stop() : start(Hyprland.focusedMonitor?.name ?? "focused")
    }

    function start(target) {
        file = dir + "/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".mp4"
        // exec, so the signal from stop() reaches the recorder itself; 130 = region selection cancelled
        const capture = target === "region"
            ? 'geom=$(slurp -d -f "%wx%h+%x+%y") || exit 130; exec gpu-screen-recorder -w region -region "$geom"'
            : 'exec gpu-screen-recorder -w "$3"'
        proc.command = ["sh", "-c", `mkdir -p "$1" && ${capture} -f 60 -a default_output -c mp4 -o "$2"`, "sh", dir, file, target]
        elapsed = 0
        proc.running = true
    }

    function stop() {
        // SIGINT lets gpu-screen-recorder finish writing the file
        proc.signal(2)
    }

    Process {
        id: proc
        onExited: code => {
            if (code === 130) return
            const saved = code === 0
            Quickshell.execDetached(["sh", "-c", saved
                ? 'a=$(notify-send -a "Screen recorder" -i video-x-generic -A open=Open "Recording saved" "$1"); [ "$a" = open ] && xdg-open "$1"'
                : 'notify-send -u critical -a "Screen recorder" -i dialog-error "Recording failed" "gpu-screen-recorder exited with code $2"',
                "sh", recorder.file, String(code)])
        }
    }

    Timer {
        running: recorder.recording
        interval: 1000
        repeat: true
        onTriggered: recorder.elapsed++
    }
}

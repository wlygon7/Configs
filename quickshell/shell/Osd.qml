import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

// Volume and mic-mute OSD on the focused monitor
PanelWindow {
    id: osd

    // Set while the sound popout is open, since it already shows the level
    property bool suppressed: false

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false

    property string mode: "volume" // volume | mic
    property bool ready: false
    property bool shown: false

    readonly property bool isMic: mode === "mic"
    readonly property bool silent: isMic ? micMuted : muted
    readonly property real level: silent ? 0 : Math.min(1, isMic ? micVolume : volume)

    function poke(newMode) {
        if (!ready || suppressed) return
        mode = newMode
        shown = true
        hide.restart()
    }

    onVolumeChanged: poke("volume")
    onMutedChanged: poke("volume")
    onMicMutedChanged: poke("mic")

    PwObjectTracker { objects: [osd.sink, osd.source] }

    // Ignore the burst of changes while PipeWire starts up
    Timer { interval: 2000; running: true; onTriggered: osd.ready = true }
    Timer { id: hide; interval: 1400; onTriggered: osd.shown = false }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors.bottom: true
    margins.bottom: 70
    implicitWidth: 360
    implicitHeight: 100
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    visible: shown || card.opacity > 0
    WlrLayershell.namespace: "qs-osd"
    WlrLayershell.layer: WlrLayer.Overlay

    GlassCard {
        id: card

        anchors.centerIn: parent
        width: 300
        height: 56
        radius: height / 2
        padding: 0
        opacity: osd.shown ? 1 : 0
        scale: osd.shown ? 1 : 0.92
        transform: Translate {
            y: osd.shown ? 0 : 10
            Behavior on y { NumberAnimation { duration: Theme.medium; easing.type: Easing.OutCubic } }
        }

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 22
            spacing: 14

            Glyph {
                Layout.preferredWidth: 22
                size: 20
                icon: osd.isMic ? (osd.micMuted ? Icons.micOff : Icons.mic)
                    : osd.muted ? Icons.volumeOff
                    : osd.volume > 0.6 ? Icons.volumeHigh
                    : osd.volume > 0.25 ? Icons.volumeMedium
                    : Icons.volumeLow
                color: osd.silent ? Theme.fgMuted : Theme.fg
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                radius: 3
                color: Qt.alpha(Theme.fg, 0.14)

                Rectangle {
                    width: parent.width * osd.level
                    height: parent.height
                    radius: 3
                    color: Theme.primary

                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }
            }

            BarText {
                Layout.preferredWidth: 46
                horizontalAlignment: Text.AlignRight
                text: osd.silent ? "Muted" : osd.isMic ? "On" : Math.round(osd.volume * 100) + "%"
                color: osd.silent ? Theme.fgMuted : Theme.fg
                font.features: { "tnum": 1 }
            }
        }
    }
}

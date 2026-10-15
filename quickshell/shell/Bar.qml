import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

PanelWindow {
    id: bar

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    // Which popout is open on this screen ("" for none) and where it points
    property string popout: ""
    property real popoutX: 0

    function toggle(name, item) {
        if (popout === name) {
            popout = ""
            return
        }
        popoutX = item.mapToItem(null, item.width / 2, 0).x
        popout = name
    }

    // For IPC, where there is no clicked item to anchor to
    function open(name) {
        const items = { calendar: clockButton, audio: volumeButton, media: mediaChip, power: powerButton, control: bellButton }
        if (items[name]?.visible) toggle(name, items[name])
    }

    anchors { top: true; left: true; right: true }
    // Extra room below the islands for their shadows, without reserving it from windows
    implicitHeight: Theme.barTop + Theme.barHeight + 12
    exclusiveZone: Theme.barTop + Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "qs-bar"
    WlrLayershell.layer: WlrLayer.Top

    SystemClock { id: clock; precision: SystemClock.Minutes }

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    PwObjectTracker { objects: [bar.sink] }

    IdleInhibitor {
        window: bar
        enabled: KeepAwake.enabled
    }

    // ---------- left: launcher, workspaces, focused window ----------
    Island {
        anchors.left: parent.left
        anchors.leftMargin: Theme.edgeGap
        y: Theme.barTop

        BarButton {
            padding: 8
            onClicked: Quickshell.execDetached(["sh", "-c", "pkill -x wofi || wofi --show drun"])

            Glyph {
                icon: Icons.cachyos
                size: 17
                color: Theme.primary
            }
        }

        Workspaces { monitor: bar.monitor }

        Divider { visible: activeWindow.visible }

        ActiveWindow {
            id: activeWindow
            monitor: bar.monitor
        }
    }

    // ---------- center: media, clock ----------
    Island {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.barTop

        MediaChip {
            id: mediaChip
            bar: bar
        }

        Divider { visible: mediaChip.visible }

        BarButton {
            id: clockButton
            active: bar.popout === "calendar"
            padding: 12
            spacing: 8
            onClicked: bar.toggle("calendar", clockButton)

            BarText {
                text: Qt.formatDateTime(clock.date, "ddd MMM d")
                color: Theme.fgMuted
            }
            BarText {
                text: Qt.formatDateTime(clock.date, "HH:mm")
                font.weight: Font.Bold
                font.features: { "tnum": 1 }
            }
        }
    }

    // ---------- right: tray, status, power ----------
    Island {
        anchors.right: parent.right
        anchors.rightMargin: Theme.edgeGap
        y: Theme.barTop

        Tray {
            id: tray
            bar: bar
        }

        Divider { visible: tray.visible }

        // Recording: pulsing dot and timer, click to stop
        BarButton {
            visible: Recorder.recording
            padding: 10
            color: hovered ? Qt.alpha(Theme.error, 0.30) : Qt.alpha(Theme.error, 0.18)
            onClicked: Recorder.stop()

            Rectangle {
                implicitWidth: 8
                implicitHeight: 8
                radius: 4
                color: Theme.error

                SequentialAnimation on opacity {
                    running: Recorder.recording
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                }
            }
            BarText {
                text: Recorder.time
                color: Theme.error
                font.features: { "tnum": 1 }
            }
        }

        BarButton {
            padding: 8
            onClicked: Quickshell.execDetached(["kitty", "--class", "kitty-float", "-e", "nmtui"])

            Glyph {
                icon: Net.icon
                color: Net.kind === "none" ? Theme.error : Theme.fg
            }
        }

        BarButton {
            id: volumeButton
            active: bar.popout === "audio"
            padding: 8
            onClicked: event => {
                if (event.button === Qt.MiddleButton) bar.sink.audio.muted = !bar.muted
                else bar.toggle("audio", volumeButton)
            }
            onScrolled: delta => {
                if (!bar.sink?.audio) return
                bar.sink.audio.muted = false
                bar.sink.audio.volume = Math.max(0, Math.min(1, Math.round((bar.volume + delta / 120 * 0.05) * 100) / 100))
            }

            Glyph {
                icon: bar.muted ? Icons.volumeOff
                    : bar.volume > 0.6 ? Icons.volumeHigh
                    : bar.volume > 0.25 ? Icons.volumeMedium
                    : Icons.volumeLow
                color: bar.muted ? Theme.fgMuted : Theme.fg
            }
            BarText {
                text: Math.round(bar.volume * 100) + "%"
                color: bar.muted ? Theme.fgMuted : Theme.fg
                font.features: { "tnum": 1 }
            }
        }

        // Keep awake lives in quick settings; this only shows while it's on (click to turn off)
        BarButton {
            visible: KeepAwake.enabled
            padding: 8
            active: true
            onClicked: KeepAwake.toggle()

            Glyph {
                icon: Icons.coffee
                color: Theme.primary
            }
        }

        // Left: notification centre and quick settings. Right: do not disturb. Middle: dismiss all.
        BarButton {
            id: bellButton
            padding: 8
            active: bar.popout === "control" || Dunst.paused
            onClicked: event => {
                if (event.button === Qt.RightButton) Dunst.toggleDnd()
                else if (event.button === Qt.MiddleButton) Dunst.closeAll()
                else bar.toggle("control", bellButton)
            }

            Glyph {
                // While paused, the badge counts notifications dunst is holding back
                readonly property int count: Dunst.paused ? Dunst.waiting : Dunst.unread

                icon: Dunst.paused ? Icons.bellSleep : Icons.bell
                color: Dunst.paused ? Theme.primary : Theme.fg

                Rectangle {
                    visible: parent.count > 0
                    anchors { right: parent.right; top: parent.top; rightMargin: -5; topMargin: -3 }
                    width: Math.max(14, badge.implicitWidth + 6)
                    height: 14
                    radius: 7
                    color: Theme.primary
                    border.width: 2
                    border.color: Theme.surface

                    BarText {
                        id: badge
                        anchors.centerIn: parent
                        text: parent.parent.count > 9 ? "9+" : parent.parent.count
                        color: Theme.primaryFg
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }
            }
        }

        BarButton {
            id: powerButton
            active: bar.popout === "power"
            padding: 8
            onClicked: bar.toggle("power", powerButton)

            Glyph {
                icon: Icons.power
                color: powerButton.active || powerButton.hovered ? Theme.error : Theme.fg
            }
        }
    }
}

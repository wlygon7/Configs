pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

ShellRoot {
    id: root

    Colors { id: c }

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    property bool ready: false
    property bool shown: false

    // Ignore the changes that happen while PipeWire is still starting up
    Timer { interval: 2000; running: true; onTriggered: root.ready = true }
    Timer { id: hideTimer; interval: 1500; onTriggered: root.shown = false }

    function poke() {
        if (!ready) return
        shown = true
        hideTimer.restart()
    }

    onVolChanged: poke()
    onMutedChanged: poke()

    PanelWindow {
        visible: root.shown || card.opacity > 0.01
        color: "transparent"
        anchors { bottom: true }
        margins { bottom: 96 }
        implicitWidth: 300
        implicitHeight: 64
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-osd"

        Rectangle {
            id: card
            anchors.fill: parent
            radius: 20
            color: Qt.alpha(c.surface, 0.60)
            border.width: 1
            border.color: Qt.alpha(c.on_surface, 0.12)
            opacity: root.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                Text {
                    text: root.muted ? "mute" : "vol"
                    color: c.on_surface
                    font.pixelSize: 14
                    font.bold: true
                    Layout.preferredWidth: 36
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    radius: 3
                    color: Qt.alpha(c.on_surface, 0.15)
                    Rectangle {
                        width: parent.width * (root.muted ? 0 : Math.min(1, root.vol))
                        height: parent.height
                        radius: 3
                        color: c.primary
                        Behavior on width { NumberAnimation { duration: 90 } }
                    }
                }

                Text {
                    text: Math.round(root.vol * 100) + "%"
                    color: Qt.alpha(c.on_surface, 0.65)
                    font.pixelSize: 13
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}

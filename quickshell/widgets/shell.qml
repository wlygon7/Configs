pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris

ShellRoot {
    id: root

    property int cpu: 0
    property int ram: 0
    property int gpuTemp: 0
    property real prevTotal: 0
    property real prevIdle: 0

    Colors { id: c }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // Spotify only, so the wallpaper video is never treated as music
    readonly property var player: {
        const list = Mpris.players.values
        return list.find(p => p.dbusName.toLowerCase().includes("spotify")) ?? null
    }

    Process {
        id: statsProc
        command: ["bash", "/home/wlygon7/.config/quickshell/widgets/stats.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                if (lines.length < 3) return
                const f = lines[0].trim().split(/\s+/).slice(1).map(Number)
                const idle = (f[3] ?? 0) + (f[4] ?? 0)
                const total = f.slice(0, 8).reduce((a, b) => a + b, 0)
                if (root.prevTotal > 0 && total > root.prevTotal)
                    root.cpu = Math.round(100 * (1 - (idle - root.prevIdle) / (total - root.prevTotal)))
                root.prevTotal = total
                root.prevIdle = idle
                root.ram = parseInt(lines[1]) || 0
                root.gpuTemp = parseInt(lines[2].split(",")[0]) || 0
            }
        }
    }

    Timer {
        running: true
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: statsProc.running = true
    }

    Timer {
        running: root.player !== null && root.player.isPlaying
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    // ================= CLOCK =================
    PanelWindow {
        color: "transparent"
        anchors { top: true; left: true }
        margins { top: 90; left: 24 }
        implicitWidth: 300
        implicitHeight: 140
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "qs-widgets"

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: Qt.alpha(c.surface, 0.50)
            border.width: 1
            border.color: Qt.alpha(c.on_surface, 0.12)

            Column {
                anchors.centerIn: parent
                spacing: 4
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: c.on_surface
                    font.pixelSize: 64
                    font.bold: true
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                    color: Qt.alpha(c.on_surface, 0.65)
                    font.pixelSize: 15
                }
            }
        }
    }

    // ================= SYSTEM STATS =================
    PanelWindow {
        color: "transparent"
        anchors { top: true; right: true }
        margins { top: 90; right: 24 }
        implicitWidth: 280
        implicitHeight: statsCol.implicitHeight + 36
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "qs-widgets"

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: Qt.alpha(c.surface, 0.50)
            border.width: 1
            border.color: Qt.alpha(c.on_surface, 0.12)

            ColumnLayout {
                id: statsCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
                spacing: 12

                Text {
                    text: "System"
                    color: c.on_surface
                    font.pixelSize: 14
                    font.bold: true
                }

                Repeater {
                    model: [
                        { l: "CPU", v: root.cpu, t: root.cpu + "%" },
                        { l: "RAM", v: root.ram, t: root.ram + "%" },
                        { l: "GPU temp", v: root.gpuTemp, t: root.gpuTemp > 0 ? root.gpuTemp + "°C" : "--" }
                    ]
                    delegate: ColumnLayout {
                        id: row
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.l
                                color: Qt.alpha(c.on_surface, 0.65)
                                font.pixelSize: 12
                            }
                            Text {
                                text: row.modelData.t
                                color: c.on_surface
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 5
                            radius: 3
                            color: Qt.alpha(c.on_surface, 0.15)
                            Rectangle {
                                width: parent.width * Math.min(1, row.modelData.v / 100)
                                height: parent.height
                                radius: 3
                                color: c.primary
                                Behavior on width { NumberAnimation { duration: 300 } }
                            }
                        }
                    }
                }
            }
        }
    }

    // ================= NOW PLAYING =================
    PanelWindow {
        color: "transparent"
        anchors { bottom: true; left: true }
        margins { bottom: 24; left: 24 }
        implicitWidth: 380
        implicitHeight: mediaCol.implicitHeight + 32
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "qs-widgets"

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: Qt.alpha(c.surface, 0.50)
            border.width: 1
            border.color: Qt.alpha(c.on_surface, 0.12)

            ColumnLayout {
                id: mediaCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 76
                        Layout.preferredHeight: 76
                        radius: 10
                        color: Qt.alpha(c.on_surface, 0.10)
                        Image {
                            anchors.fill: parent
                            source: root.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: root.player?.trackTitle ?? "Nothing playing"
                            color: c.on_surface
                            font.pixelSize: 15
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.player?.trackArtist ?? ""
                            color: Qt.alpha(c.on_surface, 0.65)
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                        RowLayout {
                            spacing: 8
                            Repeater {
                                model: ["prev", root.player && root.player.isPlaying ? "pause" : "play", "next"]
                                delegate: Rectangle {
                                    id: btn
                                    required property string modelData
                                    required property int index
                                    implicitWidth: label.implicitWidth + 24
                                    implicitHeight: 28
                                    radius: 14
                                    color: ma.containsMouse ? Qt.alpha(c.primary, 0.35) : Qt.alpha(c.on_surface, 0.10)
                                    Text {
                                        id: label
                                        anchors.centerIn: parent
                                        text: btn.modelData
                                        color: c.on_surface
                                        font.pixelSize: 12
                                    }
                                    MouseArea {
                                        id: ma
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (!root.player) return
                                            if (btn.index === 0) root.player.previous()
                                            else if (btn.index === 1) root.player.togglePlaying()
                                            else root.player.next()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 4
                    radius: 2
                    color: Qt.alpha(c.on_surface, 0.15)
                    Rectangle {
                        width: parent.width * (root.player && root.player.length > 0
                            ? Math.min(1, root.player.position / root.player.length) : 0)
                        height: parent.height
                        radius: 2
                        color: c.primary
                    }
                }
            }
        }
    }
}

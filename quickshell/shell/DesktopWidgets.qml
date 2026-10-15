pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Clock, system stats and now playing, on the desktop layer of the first monitor (under windows)
Scope {
    id: root

    readonly property ShellScreen screen: Quickshell.screens[0] ?? null
    // Below the bar, on the same 20px grid as the windows
    readonly property int top: Theme.barTop + Theme.barHeight + Theme.edgeGap

    property int cpu: 0
    property int ram: 0
    property int gpuTemp: 0
    property int gpuLoad: 0
    property real prevTotal: 0
    property real prevIdle: 0

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Process {
        id: stats
        command: ["bash", Quickshell.shellPath("stats.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                if (lines.length < 3) return
                const fields = lines[0].trim().split(/\s+/).slice(1).map(Number)
                const idle = (fields[3] ?? 0) + (fields[4] ?? 0)
                const total = fields.slice(0, 8).reduce((a, b) => a + b, 0)
                if (root.prevTotal > 0 && total > root.prevTotal)
                    root.cpu = Math.round(100 * (1 - (idle - root.prevIdle) / (total - root.prevTotal)))
                root.prevTotal = total
                root.prevIdle = idle
                root.ram = parseInt(lines[1]) || 0
                const gpu = lines[2].split(",")
                root.gpuTemp = parseInt(gpu[0]) || 0
                root.gpuLoad = parseInt(gpu[1]) || 0
            }
        }
    }

    Timer {
        running: true
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: stats.running = true
    }

    component DesktopWindow: PanelWindow {
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "qs-widgets"
    }

    // ---------- clock ----------
    DesktopWindow {
        screen: root.screen
        anchors { top: true; left: true }
        margins { top: root.top; left: Theme.edgeGap }
        implicitWidth: 300
        implicitHeight: 150
        mask: Region {}

        GlassCard {
            anchors.fill: parent

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                BarText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    font.pixelSize: 64
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                }
                BarText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                    color: Theme.fgMuted
                    font.pixelSize: 15
                }
            }
        }
    }

    // ---------- system stats ----------
    DesktopWindow {
        screen: root.screen
        anchors { top: true; right: true }
        margins { top: root.top; right: Theme.edgeGap }
        implicitWidth: 280
        implicitHeight: statsColumn.implicitHeight + 36
        mask: Region {}

        GlassCard {
            anchors.fill: parent

            ColumnLayout {
                id: statsColumn
                width: parent.width
                spacing: 14

                BarText {
                    text: "System"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Repeater {
                    model: [
                        { icon: Icons.chip, label: "CPU", value: root.cpu, text: root.cpu + "%" },
                        { icon: Icons.memory, label: "Memory", value: root.ram, text: root.ram + "%" },
                        { icon: Icons.gpu, label: "GPU", value: root.gpuLoad, text: root.gpuTemp > 0 ? root.gpuTemp + "°C  ·  " + root.gpuLoad + "%" : "--" }
                    ]

                    delegate: ColumnLayout {
                        id: stat

                        required property var modelData

                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Glyph {
                                icon: stat.modelData.icon
                                size: 15
                                color: Theme.primary
                            }
                            BarText {
                                Layout.fillWidth: true
                                text: stat.modelData.label
                                color: Theme.fgMuted
                                font.pixelSize: 12
                            }
                            BarText {
                                text: stat.modelData.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                font.features: { "tnum": 1 }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            radius: 3
                            color: Qt.alpha(Theme.fg, 0.12)

                            Rectangle {
                                width: parent.width * Math.min(1, stat.modelData.value / 100)
                                height: parent.height
                                radius: 3
                                color: stat.modelData.value > 85 ? Theme.error : Theme.primary

                                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: Theme.medium } }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------- now playing ----------
    DesktopWindow {
        screen: root.screen
        visible: Media.player !== null
        anchors { bottom: true; left: true }
        margins { bottom: Theme.edgeGap; left: Theme.edgeGap }
        implicitWidth: player.implicitWidth + 36
        implicitHeight: player.implicitHeight + 36

        GlassCard {
            anchors.fill: parent

            MediaView {
                id: player
                width: parent.width
                active: true
            }
        }
    }
}

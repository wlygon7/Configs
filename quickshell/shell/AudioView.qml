pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)

    implicitWidth: 320
    implicitHeight: column.implicitHeight

    PwObjectTracker { objects: [root.sink, root.source] }

    component Channel: RowLayout {
        id: channel

        required property PwNode node
        required property string icon
        required property string mutedIcon
        readonly property bool muted: node?.audio?.muted ?? false

        Layout.fillWidth: true
        spacing: 10

        BarButton {
            padding: 6
            onClicked: channel.node.audio.muted = !channel.muted
            Glyph {
                icon: channel.muted ? channel.mutedIcon : channel.icon
                color: channel.muted ? Theme.fgMuted : Theme.fg
            }
        }
        VolumeSlider {
            Layout.fillWidth: true
            value: channel.node?.audio?.volume ?? 0
            dimmed: channel.muted
            onMoved: value => {
                channel.node.audio.muted = false
                channel.node.audio.volume = value
            }
        }
        BarText {
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
            text: Math.round((channel.node?.audio?.volume ?? 0) * 100) + "%"
            color: Theme.fgMuted
            font.features: { "tnum": 1 }
        }
    }

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 10

        BarText {
            text: "Sound"
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        Channel {
            node: root.sink
            icon: Icons.volumeHigh
            mutedIcon: Icons.volumeOff
        }

        Channel {
            visible: root.source !== null
            node: root.source
            icon: Icons.mic
            mutedIcon: Icons.micOff
        }

        BarText {
            Layout.topMargin: 4
            text: "Output"
            color: Theme.fgMuted
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Repeater {
            model: root.sinks

            delegate: Rectangle {
                id: device

                required property PwNode modelData
                readonly property bool selected: modelData === Pipewire.defaultAudioSink

                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 12
                color: selected ? Qt.alpha(Theme.primary, 0.16) : pick.containsMouse ? Theme.hover : "transparent"

                Behavior on color { ColorAnimation { duration: Theme.fast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 8
                        Layout.preferredHeight: 8
                        radius: 4
                        color: device.selected ? Theme.primary : Qt.alpha(Theme.fg, 0.25)
                    }
                    BarText {
                        Layout.fillWidth: true
                        text: device.modelData.description || device.modelData.nickname || device.modelData.name
                        color: device.selected ? Theme.fg : Theme.fgMuted
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: pick
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Pipewire.preferredDefaultAudioSink = device.modelData
                }
            }
        }

        BarButton {
            Layout.alignment: Qt.AlignRight
            onClicked: Quickshell.execDetached(["pavucontrol"])
            Glyph { icon: Icons.tune; size: 14; color: Theme.primary }
            BarText { text: "Mixer"; font.pixelSize: 12; color: Theme.primary }
        }
    }
}

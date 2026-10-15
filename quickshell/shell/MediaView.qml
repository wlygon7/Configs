import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris

Item {
    id: root

    property bool active: false
    readonly property MprisPlayer player: Media.player
    readonly property real progress: player && player.length > 0 ? Math.min(1, player.position / player.length) : 0

    implicitWidth: 340
    implicitHeight: column.implicitHeight

    // MPRIS doesn't push position updates, so poll while playing
    Timer {
        running: Media.playing && root.active
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 14

        RowLayout {
            spacing: 14

            ClippingRectangle {
                Layout.preferredWidth: 76
                Layout.preferredHeight: 76
                radius: 14
                color: Qt.alpha(Theme.fg, 0.08)

                Glyph {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    icon: Icons.music
                    size: 28
                    color: Theme.fgMuted
                }
                Image {
                    id: art
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                BarText {
                    text: (root.player?.identity ?? "").toUpperCase()
                    color: Theme.primary
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                }
                BarText {
                    Layout.fillWidth: true
                    text: root.player?.trackTitle || "Nothing playing"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                BarText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.player?.trackArtist ?? ""
                    color: Theme.fgMuted
                    elide: Text.ElideRight
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.player?.lengthSupported ?? false
            spacing: 4

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 10

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Qt.alpha(Theme.fg, 0.14)

                    Rectangle {
                        width: parent.width * root.progress
                        height: parent.height
                        radius: 2
                        color: Theme.primary
                        Behavior on width { NumberAnimation { duration: 900 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.player?.canSeek ?? false
                    cursorShape: Qt.PointingHandCursor
                    onClicked: event => root.player.position = event.x / width * root.player.length
                }
            }

            RowLayout {
                BarText {
                    text: Media.time(root.player?.position ?? 0)
                    color: Theme.fgMuted
                    font.pixelSize: 11
                    font.features: { "tnum": 1 }
                }
                Item { Layout.fillWidth: true }
                BarText {
                    text: Media.time(root.player?.length ?? 0)
                    color: Theme.fgMuted
                    font.pixelSize: 11
                    font.features: { "tnum": 1 }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 14

            BarButton {
                padding: 8
                enabled: root.player?.canGoPrevious ?? false
                opacity: enabled ? 1 : 0.4
                onClicked: root.player.previous()
                Glyph { icon: Icons.previous; size: 20 }
            }

            Rectangle {
                Layout.preferredWidth: 46
                Layout.preferredHeight: 46
                radius: 23
                color: Theme.primary
                scale: playMouse.pressed ? 0.92 : playMouse.containsMouse ? 1.05 : 1

                Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutQuad } }

                Glyph {
                    anchors.centerIn: parent
                    icon: Media.playing ? Icons.pause : Icons.play
                    size: 22
                    color: Theme.primaryFg
                }
                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player?.togglePlaying()
                }
            }

            BarButton {
                padding: 8
                enabled: root.player?.canGoNext ?? false
                opacity: enabled ? 1 : 0.4
                onClicked: root.player.next()
                Glyph { icon: Icons.next; size: 20 }
            }
        }
    }
}

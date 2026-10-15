pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// Now playing: animated equalizer + track. Click for the player, middle-click to play/pause.
BarButton {
    id: chip

    required property var bar

    visible: Media.visible
    active: bar.popout === "media"
    padding: 10
    spacing: 8

    onClicked: event => {
        if (event.button === Qt.MiddleButton) Media.player.togglePlaying()
        else bar.toggle("media", chip)
    }

    Item {
        implicitWidth: 14
        implicitHeight: 12

        Row {
            anchors.bottom: parent.bottom
            spacing: 2

            Repeater {
                model: 3

                delegate: Rectangle {
                    id: eq
                    required property int index
                    readonly property int period: 320 + index * 110
                    // Uneven resting heights so a paused player reads as an equalizer, not "..."
                    readonly property int rest: [6, 10, 7][index]

                    anchors.bottom: parent.bottom
                    width: 3
                    height: rest
                    radius: 1.5
                    color: Media.playing ? Theme.primary : Qt.alpha(Theme.fg, 0.45)

                    Behavior on color { ColorAnimation { duration: Theme.medium } }

                    SequentialAnimation on height {
                        running: Media.playing
                        loops: Animation.Infinite
                        NumberAnimation { to: 12; duration: eq.period; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 4; duration: eq.period; easing.type: Easing.InOutSine }
                        onStopped: eq.height = eq.rest
                    }
                }
            }
        }
    }

    BarText {
        Layout.maximumWidth: 220
        text: Media.player?.trackTitle ?? ""
        elide: Text.ElideRight
    }

    BarText {
        Layout.maximumWidth: 140
        visible: text !== ""
        text: Media.player?.trackArtist ?? ""
        color: Theme.fgMuted
        elide: Text.ElideRight
    }
}

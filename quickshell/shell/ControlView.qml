pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

// Quick settings on top, notification history below. Opened from the bell or SUPER+Space.
Item {
    id: root

    property bool active: false

    signal done()

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property var btConnected: adapter?.devices.values.filter(d => d.connected) ?? []
    readonly property PwNode mic: Pipewire.defaultAudioSource
    readonly property bool micMuted: mic?.audio?.muted ?? false

    implicitWidth: tiles.implicitWidth
    implicitHeight: column.implicitHeight

    PwObjectTracker { objects: [root.mic] }

    // Opening the centre counts as reading what's in it
    onActiveChanged: {
        Dunst.watching = active
        if (active) {
            Dunst.refresh()
            Dunst.markRead()
        }
    }
    Connections {
        target: Dunst
        function onHistoryChanged() {
            if (root.active) Dunst.markRead()
        }
    }

    // Runs after the popout has closed, so it isn't in the screenshot or recording
    function afterClose(action) {
        delay.action = action
        delay.restart()
        root.done()
    }
    Timer {
        id: delay
        property var action: null
        interval: 250
        onTriggered: action?.()
    }

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 14

        GridLayout {
            id: tiles
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            Tile {
                icon: Net.wifiEnabled ? Icons.wifi : Icons.wifiOff
                label: "Wi-Fi"
                checked: Net.wifiEnabled
                detail: !Net.wifiEnabled ? "Off" : Net.kind === "wifi" ? Net.name : "Not connected"
                onToggled: Net.setWifi(!Net.wifiEnabled)
                onSecondary: root.afterClose(() => Quickshell.execDetached(["kitty", "--class", "kitty-float", "-e", "nmtui"]))
            }
            Tile {
                icon: root.adapter?.enabled ? Icons.bluetooth : Icons.bluetoothOff
                label: "Bluetooth"
                available: root.adapter !== null
                checked: root.adapter?.enabled ?? false
                detail: root.adapter === null ? "No adapter"
                    : !root.adapter.enabled ? "Off"
                    : root.btConnected.length > 0 ? root.btConnected.map(d => d.name || d.deviceName).join(", ")
                    : "On"
                onToggled: root.adapter.enabled = !root.adapter.enabled
                onSecondary: root.afterClose(() => Quickshell.execDetached(["kitty", "--class", "kitty-float", "-e", "bluetoothctl"]))
            }
            Tile {
                icon: Dunst.paused ? Icons.bellSleep : Icons.bell
                label: "Do not disturb"
                checked: Dunst.paused
                detail: !Dunst.paused ? "Off" : Dunst.waiting > 0 ? Dunst.waiting + " waiting" : "On"
                onToggled: Dunst.toggleDnd()
            }
            Tile {
                icon: Icons.night
                label: "Night light"
                available: NightLight.available
                checked: NightLight.available && NightLight.enabled
                detail: !NightLight.available ? "Not installed" : NightLight.enabled ? NightLight.temperature + "K" : "Off"
                onToggled: NightLight.toggle()
            }
            Tile {
                icon: root.micMuted ? Icons.micOff : Icons.mic
                label: "Microphone"
                available: root.mic !== null
                checked: !root.micMuted
                detail: root.mic === null ? "No input" : root.micMuted ? "Muted" : "On"
                onToggled: root.mic.audio.muted = !root.micMuted
                onSecondary: root.afterClose(() => Quickshell.execDetached(["pavucontrol", "-t", "4"]))
            }
            Tile {
                icon: KeepAwake.enabled ? Icons.coffee : Icons.coffeeOutline
                label: "Keep awake"
                checked: KeepAwake.enabled
                detail: KeepAwake.enabled ? "Screens stay on" : "Off"
                onToggled: KeepAwake.toggle()
            }
            Tile {
                icon: Recorder.recording ? Icons.stop : Icons.record
                label: Recorder.recording ? "Stop recording" : "Record screen"
                checked: Recorder.recording
                detail: Recorder.recording ? Recorder.time : "This monitor"
                onToggled: Recorder.recording ? Recorder.stop() : root.afterClose(() => Recorder.toggleScreen())
            }
            Tile {
                icon: Icons.screenshot
                label: "Screenshot"
                detail: "Select an area"
                onToggled: root.afterClose(() => Quickshell.execDetached(["flameshot", "gui"]))
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.divider
        }

        RowLayout {
            Layout.fillWidth: true

            BarText {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                text: "Notifications"
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
            BarButton {
                visible: Dunst.history.length > 0
                onClicked: Dunst.clear()
                Glyph { icon: Icons.clearAll; size: 14; color: Theme.primary }
                BarText { text: "Clear all"; font.pixelSize: 12; color: Theme.primary }
            }
        }

        // Empty state
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            Layout.bottomMargin: 10
            visible: Dunst.history.length === 0
            spacing: 6

            Glyph {
                Layout.alignment: Qt.AlignHCenter
                icon: Icons.bell
                size: 26
                color: Qt.alpha(Theme.fgMuted, 0.6)
            }
            BarText {
                Layout.alignment: Qt.AlignHCenter
                text: "You're all caught up"
                color: Theme.fgMuted
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 320)
            visible: Dunst.history.length > 0
            clip: true
            spacing: 6
            boundsBehavior: Flickable.StopAtBounds
            model: Dunst.history

            delegate: Rectangle {
                id: card

                required property var modelData

                width: list.width
                implicitHeight: content.implicitHeight + 24
                radius: 16
                color: hover.hovered ? Qt.alpha(Theme.fg, 0.09) : Qt.alpha(Theme.fg, 0.05)
                border.width: modelData.urgency === "CRITICAL" ? 1 : 0
                border.color: Theme.error

                Behavior on color { ColorAnimation { duration: Theme.fast } }

                HoverHandler { id: hover }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Dunst.show(card.modelData.id)
                }

                RowLayout {
                    id: content
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: 12

                    Image {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignTop
                        source: card.modelData.icon ? "file://" + card.modelData.icon : ""
                        sourceSize: Qt.size(64, 64)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        BarText {
                            Layout.fillWidth: true
                            text: card.modelData.app + "  ·  " + Dunst.age(card.modelData.age)
                            color: Theme.fgMuted
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                        BarText {
                            Layout.fillWidth: true
                            text: card.modelData.summary
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        BarText {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: card.modelData.body
                            textFormat: Text.StyledText
                            color: Theme.fgMuted
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }
                }

                BarButton {
                    anchors { right: parent.right; top: parent.top; margins: 6 }
                    padding: 4
                    opacity: hover.hovered ? 1 : 0
                    onClicked: Dunst.remove(card.modelData.id)

                    Behavior on opacity { NumberAnimation { duration: Theme.fast } }

                    Glyph { icon: Icons.close; size: 14; color: Theme.fgMuted }
                }
            }
        }
    }
}

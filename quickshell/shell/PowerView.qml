pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

// Destructive actions need a second click within 3 seconds
ColumnLayout {
    id: root

    property string armed: ""
    property bool active: false

    signal done()

    spacing: 2

    onActiveChanged: if (!active) armed = ""

    Timer { id: disarm; interval: 3000; onTriggered: root.armed = "" }

    Repeater {
        model: [
            { id: "lock", label: "Lock", icon: Icons.lock, confirm: false, cmd: "pidof hyprlock || hyprlock" },
            { id: "suspend", label: "Suspend", icon: Icons.sleep, confirm: false, cmd: "pidof hyprlock || hyprlock & sleep 1; systemctl suspend" },
            { id: "logout", label: "Log out", icon: Icons.logout, confirm: true, cmd: "command -v hyprshutdown >/dev/null && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'" },
            { id: "reboot", label: "Restart", icon: Icons.restart, confirm: true, cmd: "systemctl reboot" },
            { id: "poweroff", label: "Shut down", icon: Icons.power, confirm: true, cmd: "systemctl poweroff" }
        ]

        delegate: Rectangle {
            id: action

            required property var modelData
            readonly property bool armed: root.armed === modelData.id

            Layout.preferredWidth: 230
            Layout.preferredHeight: 40
            radius: 14
            color: armed ? Qt.alpha(Theme.error, 0.20) : mouse.containsMouse ? Theme.hover : "transparent"

            Behavior on color { ColorAnimation { duration: Theme.fast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                spacing: 14

                Glyph {
                    icon: action.modelData.icon
                    color: action.armed ? Theme.error : Theme.fg
                }
                BarText {
                    Layout.fillWidth: true
                    text: action.armed ? "Click again to " + action.modelData.label.toLowerCase() : action.modelData.label
                    color: action.armed ? Theme.error : Theme.fg
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (action.modelData.confirm && !action.armed) {
                        root.armed = action.modelData.id
                        disarm.restart()
                        return
                    }
                    root.done()
                    Quickshell.execDetached(["sh", "-c", action.modelData.cmd])
                }
            }
        }
    }
}

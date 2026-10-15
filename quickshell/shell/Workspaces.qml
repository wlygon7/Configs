pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland

// Dots at rest, numbers on hover. The active workspace is a pill that slides between slots.
Item {
    id: root

    required property HyprlandMonitor monitor
    readonly property bool expanded: hover.hovered
    readonly property int count: {
        let highest = 5
        for (const ws of Hyprland.workspaces.values)
            if (ws.id > highest) highest = ws.id
        return Math.min(highest, 10)
    }
    property real wheelAccum: 0

    implicitWidth: row.implicitWidth + 8
    implicitHeight: Theme.chipHeight

    HoverHandler { id: hover }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            root.wheelAccum += event.angleDelta.y
            if (Math.abs(root.wheelAccum) < 120) return
            const step = root.wheelAccum > 0 ? "e-1" : "e+1"
            root.wheelAccum = 0
            Hyprland.dispatch(`hl.dsp.focus({ workspace = "${step}" })`)
        }
    }

    Row {
        id: row
        anchors.centerIn: parent

        Repeater {
            model: root.count

            delegate: Item {
                id: slot

                required property int index
                readonly property int wsId: index + 1
                readonly property HyprlandWorkspace ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                readonly property bool occupied: (ws?.toplevels.values.length ?? 0) > 0
                readonly property bool current: root.monitor?.activeWorkspace?.id === wsId
                // shown on the other monitor right now
                readonly property bool elsewhere: !current && (ws?.active ?? false)
                readonly property bool urgent: ws?.urgent ?? false

                width: current ? (root.expanded ? 34 : 30) : (root.expanded ? 24 : 16)
                height: Theme.chipHeight

                Behavior on width { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutQuint } }

                Rectangle {
                    anchors.centerIn: parent
                    width: slot.current ? slot.width - (root.expanded ? 6 : 8)
                        : root.expanded ? 20
                        : slot.occupied || slot.elsewhere ? 7 : 5
                    height: root.expanded ? 20 : slot.current ? 8 : width
                    radius: height / 2
                    color: slot.urgent ? Theme.error
                        : slot.current ? (root.monitor?.focused ? Theme.primary : Qt.alpha(Theme.primary, 0.55))
                        : slot.elsewhere ? Qt.alpha(Theme.primary, root.expanded ? 0.22 : 0.5)
                        : slot.occupied ? Qt.alpha(Theme.fg, root.expanded ? 0.12 : 0.7)
                        : Qt.alpha(Theme.fg, root.expanded ? 0.06 : 0.32)

                    Behavior on width { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutQuint } }
                    Behavior on height { NumberAnimation { duration: Theme.medium; easing.type: Easing.OutQuint } }
                    Behavior on color { ColorAnimation { duration: Theme.medium } }

                    BarText {
                        anchors.centerIn: parent
                        text: slot.wsId
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        opacity: root.expanded ? 1 : 0
                        color: slot.current ? Theme.primaryFg
                            : Qt.alpha(Theme.fg, slot.occupied ? 0.95 : 0.45)

                        Behavior on opacity { NumberAnimation { duration: Theme.medium } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${slot.wsId} })`)
                }
            }
        }
    }
}

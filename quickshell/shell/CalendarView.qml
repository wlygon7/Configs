pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root

    property date month: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)
    readonly property bool thisMonth: month.getFullYear() === clock.date.getFullYear()
        && month.getMonth() === clock.date.getMonth()

    // Six weeks starting on the Sunday before the 1st
    readonly property var cells: {
        const start = new Date(month.getFullYear(), month.getMonth(), 1 - month.getDay())
        const today = clock.date
        const out = []
        for (let i = 0; i < 42; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === month.getMonth(),
                today: d.toDateString() === today.toDateString()
            })
        }
        return out
    }

    function shift(months) {
        month = new Date(month.getFullYear(), month.getMonth() + months, 1)
    }

    spacing: 12

    // Views stay loaded between opens (see Popouts), so start back on this month each time
    property bool active: false
    onActiveChanged: if (active) month = new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)

    SystemClock { id: clock; precision: SystemClock.Minutes }

    WheelHandler {
        onWheel: event => root.shift(event.angleDelta.y > 0 ? -1 : 1)
    }

    ColumnLayout {
        spacing: 0
        BarText {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.pixelSize: 36
            font.weight: Font.DemiBold
        }
        BarText {
            text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
            color: Theme.fgMuted
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Theme.divider
    }

    RowLayout {
        spacing: 2

        BarText {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            text: Qt.formatDate(root.month, "MMMM yyyy")
            font.weight: Font.DemiBold
        }
        BarButton {
            visible: !root.thisMonth
            onClicked: root.month = new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)
            BarText { text: "Today"; font.pixelSize: 12; color: Theme.primary }
        }
        BarButton {
            padding: 5
            onClicked: root.shift(-1)
            Glyph { icon: Icons.chevronLeft }
        }
        BarButton {
            padding: 5
            onClicked: root.shift(1)
            Glyph { icon: Icons.chevronRight }
        }
    }

    GridLayout {
        columns: 7
        rowSpacing: 2
        columnSpacing: 2

        Repeater {
            model: ["S", "M", "T", "W", "T", "F", "S"]
            delegate: BarText {
                required property string modelData
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Qt.alpha(Theme.fgMuted, 0.7)
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
        }

        Repeater {
            model: root.cells
            delegate: Rectangle {
                id: cell
                required property var modelData
                Layout.preferredWidth: 34
                Layout.preferredHeight: 30
                radius: 15
                color: modelData.today ? Theme.primary : "transparent"

                BarText {
                    anchors.centerIn: parent
                    text: cell.modelData.day
                    font.pixelSize: 12
                    font.weight: cell.modelData.today ? Font.Bold : Font.Medium
                    color: cell.modelData.today ? Theme.primaryFg
                        : cell.modelData.inMonth ? Theme.fg
                        : Qt.alpha(Theme.fg, 0.28)
                }
            }
        }
    }
}

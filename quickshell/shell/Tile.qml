import QtQuick
import QtQuick.Layouts

// Quick-settings toggle. Left click toggles, right click opens the related settings.
Rectangle {
    id: tile

    required property string icon
    required property string label
    property string detail: ""
    property bool checked: false
    property bool available: true

    signal toggled()
    signal secondary()

    implicitWidth: 182
    implicitHeight: 58
    radius: 18
    opacity: available ? 1 : 0.45
    color: checked ? Theme.primary
        : mouse.containsMouse && available ? Qt.alpha(Theme.fg, 0.11)
        : Qt.alpha(Theme.fg, 0.06)
    scale: mouse.pressed && available ? 0.97 : 1

    Behavior on color { ColorAnimation { duration: Theme.medium; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutQuad } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 12
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 38
            Layout.preferredHeight: 38
            radius: 19
            color: tile.checked ? Qt.alpha(Theme.primaryFg, 0.14) : Qt.alpha(Theme.fg, 0.08)

            Behavior on color { ColorAnimation { duration: Theme.medium } }

            Glyph {
                anchors.centerIn: parent
                icon: tile.icon
                size: 18
                color: tile.checked ? Theme.primaryFg : Theme.fg
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            BarText {
                Layout.fillWidth: true
                text: tile.label
                font.weight: Font.DemiBold
                color: tile.checked ? Theme.primaryFg : Theme.fg
                elide: Text.ElideRight
            }
            BarText {
                Layout.fillWidth: true
                visible: text !== ""
                text: tile.detail
                font.pixelSize: 11
                color: tile.checked ? Qt.alpha(Theme.primaryFg, 0.75) : Theme.fgMuted
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: tile.available ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (!tile.available) return
            if (event.button === Qt.RightButton) tile.secondary()
            else tile.toggled()
        }
    }
}

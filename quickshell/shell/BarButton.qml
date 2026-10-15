import QtQuick
import QtQuick.Layouts

// Pill-shaped hover target used for everything clickable in the bar
Rectangle {
    id: button

    default property alias content: row.data
    property bool active: false
    property int padding: 9
    property alias spacing: row.spacing
    readonly property bool hovered: mouse.containsMouse

    signal clicked(var event)
    signal scrolled(int delta)

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: Theme.chipHeight
    radius: height / 2
    color: active ? Qt.alpha(Theme.primary, 0.20)
        : mouse.pressed ? Theme.pressed
        : hovered ? Theme.hover
        : "transparent"
    scale: mouse.pressed ? 0.95 : 1

    Behavior on color { ColorAnimation { duration: Theme.fast } }
    Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutQuad } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => button.clicked(event)
        onWheel: event => button.scrolled(event.angleDelta.y)
    }
}

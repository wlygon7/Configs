import QtQuick

// Drag, click or scroll. Emits moved(); the owner decides what to set.
Item {
    id: slider

    property real value: 0
    property bool dimmed: false
    readonly property bool dragging: mouse.pressed

    signal moved(real value)

    function clamp(v) {
        return Math.max(0, Math.min(1, Math.round(v * 100) / 100))
    }

    implicitWidth: 200
    implicitHeight: 22

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Qt.alpha(Theme.fg, 0.14)

        Rectangle {
            width: knob.x + knob.width / 2
            height: parent.height
            radius: 3
            color: slider.dimmed ? Theme.outline : Theme.primary
        }
    }

    Rectangle {
        id: knob
        anchors.verticalCenter: parent.verticalCenter
        x: (slider.width - width) * Math.min(1, slider.value)
        width: 16
        height: 16
        radius: 8
        color: slider.dimmed ? Theme.outline : Theme.primary
        border.width: 3
        border.color: Theme.surfaceContainer
        scale: mouse.pressed || mouse.containsMouse ? 1.15 : 1

        Behavior on x { enabled: !slider.dragging; NumberAnimation { duration: Theme.fast } }
        Behavior on scale { NumberAnimation { duration: Theme.fast } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: event => slider.moved(slider.clamp(event.x / width))
        onPositionChanged: event => { if (pressed) slider.moved(slider.clamp(event.x / width)) }
        onWheel: event => slider.moved(slider.clamp(slider.value + event.angleDelta.y / 120 * 0.05))
    }
}

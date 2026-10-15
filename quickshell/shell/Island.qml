import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

// A floating glass pill. The bar is three of these.
Item {
    id: island

    default property alias content: row.data
    property int padding: 4

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: Theme.barHeight

    Behavior on implicitWidth { NumberAnimation { duration: Theme.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }

    // Drawn analytically, so it stays cheap while the island resizes
    RectangularShadow {
        anchors.fill: parent
        radius: glass.radius
        blur: 14
        offset.y: 3
        color: Theme.shadow
    }

    Rectangle {
        id: glass
        anchors.fill: parent
        radius: height / 2
        clip: true
        border.width: 1
        border.color: Theme.glassBorder
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.glassTop }
            GradientStop { position: 1; color: Theme.glass }
        }

        RowLayout {
            id: row
            x: island.padding
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
        }
    }
}

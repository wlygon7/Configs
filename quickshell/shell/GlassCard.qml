import QtQuick
import QtQuick.Effects

// The bar's glass look as a standalone card (OSD, desktop widgets)
Item {
    id: card

    default property alias content: inner.data
    property int padding: 18
    property real radius: 24

    RectangularShadow {
        anchors.fill: parent
        radius: card.radius
        blur: 24
        offset.y: 6
        color: Theme.shadow
    }

    Rectangle {
        anchors.fill: parent
        radius: card.radius
        border.width: 1
        border.color: Theme.glassBorder
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.glassTop }
            GradientStop { position: 1; color: Theme.glass }
        }
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: card.padding
    }
}

import QtQuick

// A Nerd Font icon
Text {
    property string icon
    property int size: 16

    text: icon
    color: Theme.fg
    font.family: Theme.iconFont
    font.pixelSize: size
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter

    Behavior on color { ColorAnimation { duration: Theme.fast } }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.SystemTray

// Left click activates, right click opens the app's menu, middle click is the secondary action
RowLayout {
    id: root

    required property var bar

    visible: SystemTray.items.values.length > 0
    spacing: 0

    Repeater {
        model: SystemTray.items

        delegate: BarButton {
            id: item

            required property SystemTrayItem modelData

            padding: 6

            onClicked: event => {
                if (event.button === Qt.MiddleButton) {
                    modelData.secondaryActivate()
                } else if (event.button === Qt.RightButton || modelData.onlyMenu) {
                    if (!modelData.hasMenu) return
                    const pos = item.mapToItem(null, 0, item.height + 10)
                    modelData.display(root.bar, pos.x, pos.y)
                } else {
                    modelData.activate()
                }
            }
            onScrolled: delta => modelData.scroll(delta, false)

            IconImage {
                implicitSize: 16
                // modelData goes null for a moment when an app removes its tray icon
                source: item.modelData?.icon ?? ""
            }
        }
    }
}

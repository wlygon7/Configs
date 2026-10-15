import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

// Focused window's icon and title. Only the focused monitor's bar shows it.
RowLayout {
    id: root

    required property HyprlandMonitor monitor
    readonly property HyprlandToplevel window: Hyprland.activeToplevel
    readonly property string appId: window?.wayland?.appId ?? ""
    readonly property bool shown: window !== null && window.title !== ""
        && window.monitor === monitor && window.workspace === monitor?.activeWorkspace

    visible: shown
    spacing: 8

    IconImage {
        Layout.leftMargin: 6
        implicitSize: 16
        source: Quickshell.iconPath(DesktopEntries.heuristicLookup(root.appId)?.icon ?? root.appId, "application-x-executable")
    }

    BarText {
        Layout.maximumWidth: 360
        Layout.rightMargin: 10
        text: root.window?.title ?? ""
        color: Theme.fgMuted
        elide: Text.ElideRight
    }
}

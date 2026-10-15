pragma Singleton

import QtQuick
import Quickshell

// Shared look for the bar. Colours come from Colors.qml, which matugen rewrites
// whenever the wallpaper changes (Quickshell hot-reloads it).
Singleton {
    readonly property Colors palette: Colors {}

    readonly property color surface: palette.surface
    readonly property color surfaceContainer: palette.surface_container
    readonly property color surfaceHigh: palette.surface_container_high
    readonly property color fg: palette.on_surface
    readonly property color fgMuted: palette.on_surface_variant
    readonly property color outline: palette.outline
    readonly property color primary: palette.primary
    readonly property color primaryFg: palette.on_primary
    readonly property color primaryContainer: palette.primary_container
    readonly property color primaryContainerFg: palette.on_primary_container
    readonly property color tertiary: palette.tertiary
    readonly property color error: palette.error

    // Glass. Alpha has to stay above the layer rules' ignore_alpha (0.45 bar, 0.5 popouts)
    // to get blurred, and shadows below it so they don't.
    readonly property color glass: Qt.alpha(surface, 0.58)
    readonly property color glassTop: Qt.alpha(surfaceHigh, 0.62)
    readonly property color glassBorder: Qt.alpha(fg, 0.10)
    readonly property color popout: Qt.alpha(surfaceContainer, 0.86)
    readonly property color hover: Qt.alpha(fg, 0.08)
    readonly property color pressed: Qt.alpha(fg, 0.14)
    readonly property color divider: Qt.alpha(fg, 0.12)
    readonly property color shadow: Qt.alpha("#000000", 0.35)

    readonly property string font: "Noto Sans"
    readonly property string iconFont: "JetBrainsMono Nerd Font"

    // edgeGap matches Hyprland's gaps_out so the islands line up with window edges
    readonly property int edgeGap: 20
    readonly property int barTop: 8
    readonly property int barHeight: 34
    readonly property int chipHeight: 26

    readonly property int fast: 140
    readonly property int medium: 260
    readonly property int slow: 420
    readonly property int morph: 340
    // Same curve as the "glide" bezier in hyprland.lua, so the bar moves like the windows do
    readonly property var glide: [0.22, 1, 0.36, 1, 1, 1]
}

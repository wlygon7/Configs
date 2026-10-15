import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// One card per screen that morphs between popouts. Clicking outside or pressing Escape closes it.
PanelWindow {
    id: root

    required property var bar
    readonly property bool open: bar.popout !== ""
    // Lags behind bar.popout so the content stays put while the card fades out
    property string current: ""

    screen: bar.screen
    anchors { top: true; left: true; right: true }
    implicitHeight: 900
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: open || card.opacity > 0
    mask: Region { item: card }
    WlrLayershell.namespace: "qs-bar-popout"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Connections {
        target: root.bar
        function onPopoutChanged() {
            if (root.bar.popout !== "") root.current = root.bar.popout
            // Set imperatively: the grab turns itself off when dismissed, which would break a binding
            grab.active = root.open
        }
    }

    HyprlandFocusGrab {
        id: grab
        windows: [root, root.bar]
        onCleared: root.bar.popout = ""
    }

    // Every view stays loaded so switching can crossfade instead of swapping content mid-move
    // (inline components can't see this file's ids, so whoever uses Page sets `shown`)
    component Page: Item {
        property bool shown: false
        readonly property Item view: children.length > 0 ? children[0] : null

        implicitWidth: view?.implicitWidth ?? 0
        implicitHeight: view?.implicitHeight ?? 0
        opacity: shown ? 1 : 0
        visible: opacity > 0

        // Outgoing page is nearly gone before the incoming one starts, so they don't ghost over each other.
        // Timings key off targetValue: `shown` can update after the animation has already started.
        Behavior on opacity {
            id: fade
            SequentialAnimation {
                PauseAnimation { duration: fade.targetValue > 0 ? 70 : 0 }
                NumberAnimation { duration: fade.targetValue > 0 ? 200 : 80; easing.type: Easing.OutCubic }
            }
        }
    }

    Item {
        id: card

        readonly property int pad: 16
        readonly property Page page: ({ calendar: calendarPage, audio: audioPage, media: mediaPage, power: powerPage, control: controlPage })[root.current] ?? null
        // Targets come from the destination page, never from the animated size, so the
        // move and the resize each run exactly once and finish together
        readonly property real targetWidth: (page?.implicitWidth ?? 0) + pad * 2
        readonly property real targetHeight: (page?.implicitHeight ?? 0) + pad * 2
        readonly property real targetX: Math.max(Theme.edgeGap, Math.min(root.width - targetWidth - Theme.edgeGap, root.bar.popoutX - targetWidth / 2))
        // Morph only when switching between open popouts; a fresh open just appears in place
        readonly property bool morph: root.open && opacity > 0.6

        x: targetX
        y: Theme.barTop + Theme.barHeight + 8
        width: targetWidth
        height: targetHeight
        transformOrigin: Item.Top
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.95
        transform: Translate {
            y: root.open ? 0 : -6
            Behavior on y { NumberAnimation { duration: Theme.medium; easing.type: Easing.OutCubic } }
        }

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
        Behavior on x { enabled: card.morph; NumberAnimation { duration: Theme.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
        Behavior on width { enabled: card.morph; NumberAnimation { duration: Theme.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
        Behavior on height { enabled: card.morph; NumberAnimation { duration: Theme.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }

        RectangularShadow {
            anchors.fill: parent
            radius: surface.radius
            blur: 28
            offset.y: 8
            color: Theme.shadow
        }

        Rectangle {
            id: surface
            anchors.fill: parent
            radius: 22
            clip: true
            color: Theme.popout
            border.width: 1
            border.color: Theme.glassBorder

            Item {
                x: card.pad
                y: card.pad
                focus: true

                Keys.onEscapePressed: root.bar.popout = ""

                Page { id: calendarPage; shown: root.current === "calendar"; CalendarView { active: root.open && calendarPage.shown } }
                Page { id: audioPage; shown: root.current === "audio"; AudioView {} }
                Page { id: mediaPage; shown: root.current === "media"; MediaView { active: root.open && mediaPage.shown } }
                Page {
                    id: powerPage
                    shown: root.current === "power"
                    PowerView { active: root.open && powerPage.shown; onDone: root.bar.popout = "" }
                }
                Page {
                    id: controlPage
                    shown: root.current === "control"
                    ControlView { active: root.open && controlPage.shown; onDone: root.bar.popout = "" }
                }
            }
        }
    }
}

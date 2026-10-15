pragma Singleton

import Quickshell

// Keep-awake state shared by every bar. While on, each bar's IdleInhibitor stops hypridle
// from locking or turning the screens off. Survives Quickshell reloads (e.g. a wallpaper change).
Singleton {
    readonly property bool enabled: state.enabled

    function toggle() {
        state.enabled = !state.enabled
    }

    PersistentProperties {
        id: state
        reloadableId: "keepAwake"
        property bool enabled: false
    }
}

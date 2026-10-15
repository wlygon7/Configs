//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Desktop shell: bar, popouts, OSD, desktop widgets. Run with `qs -c shell`.
// IPC: qs -c shell ipc call shell toggle <control|calendar|audio|media|power>
//      qs -c shell ipc call shell keepAwake
//      qs -c shell ipc call shell record         (select a region; again to stop)
//      qs -c shell ipc call shell recordScreen   (focused monitor; again to stop)
ShellRoot {
    Variants {
        id: screens
        model: Quickshell.screens

        delegate: Scope {
            id: scope

            required property ShellScreen modelData
            property alias bar: bar

            Bar {
                id: bar
                screen: scope.modelData
            }

            Popouts { bar: bar }
        }
    }

    Osd {
        suppressed: screens.instances.some(s => s.bar.popout === "audio")
    }

    DesktopWidgets {}

    IpcHandler {
        target: "shell"

        // Opens on the focused monitor
        function toggle(name: string): void {
            const scope = screens.instances.find(s => s.bar.monitor?.focused) ?? screens.instances[0]
            scope?.bar.open(name)
        }

        function keepAwake(): void {
            KeepAwake.toggle()
        }

        function record(): void {
            Recorder.toggleRegion()
        }

        function recordScreen(): void {
            Recorder.toggleScreen()
        }
    }
}

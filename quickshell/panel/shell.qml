pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

ShellRoot {
    id: root

    property bool open: false
    property bool wifiOn: false
    property bool btOn: false
    property bool dnd: false
    property var notifs: []
    property int cpu: 0
    property int ram: 0
    property int gpuTemp: 0
    property int gpuUtil: 0
    property real prevTotal: 0
    property real prevIdle: 0
    property var viewDate: new Date()

    onOpenChanged: {
        if (open) viewDate = new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)
    }

    Colors { id: c }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    IpcHandler {
        target: "panel"
        function toggle(): void { root.open = !root.open }
        function close(): void { root.open = false }
    }

    // Spotify only, so the wallpaper video never shows up as "music"
    readonly property var player: {
        const list = Mpris.players.values
        return list.find(p => p.dbusName.toLowerCase().includes("spotify")) ?? null
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink?.audio?.volume ?? 0

    PwObjectTracker { objects: [root.sink] }

    // ---------- calendar ----------
    function buildCells(d, now) {
        const first = new Date(d.getFullYear(), d.getMonth(), 1)
        const start = new Date(first.getFullYear(), first.getMonth(), 1 - first.getDay())
        const out = []
        for (let i = 0; i < 42; i++) {
            const cell = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
            out.push({
                day: cell.getDate(),
                inMonth: cell.getMonth() === d.getMonth(),
                today: cell.getFullYear() === now.getFullYear()
                    && cell.getMonth() === now.getMonth()
                    && cell.getDate() === now.getDate()
            })
        }
        return out
    }
    readonly property var cells: buildCells(viewDate, clock.date)

    // ---------- background data ----------
    Process {
        id: wifiProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: root.wifiOn = text.trim() === "enabled" }
    }
    Process {
        id: btProc
        command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo yes || echo no"]
        stdout: StdioCollector { onStreamFinished: root.btOn = text.trim() === "yes" }
    }
    Process {
        id: dndProc
        command: ["dunstctl", "is-paused"]
        stdout: StdioCollector { onStreamFinished: root.dnd = text.trim() === "true" }
    }
    Process {
        id: notifProc
        command: ["dunstctl", "history"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text)
                    const list = parsed.data[0] ?? []
                    root.notifs = list.map(n => ({
                        id: n.id?.data ?? 0,
                        summary: n.summary?.data ?? "",
                        body: n.body?.data ?? "",
                        app: n.appname?.data ?? ""
                    }))
                } catch (e) {
                    root.notifs = []
                }
            }
        }
    }
    Process {
        id: statsProc
        command: ["bash", "/home/wlygon7/.config/quickshell/panel/stats.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                if (lines.length < 3) return
                const f = lines[0].trim().split(/\s+/).slice(1).map(Number)
                const idle = (f[3] ?? 0) + (f[4] ?? 0)
                const total = f.slice(0, 8).reduce((a, b) => a + b, 0)
                if (root.prevTotal > 0 && total > root.prevTotal)
                    root.cpu = Math.round(100 * (1 - (idle - root.prevIdle) / (total - root.prevTotal)))
                root.prevTotal = total
                root.prevIdle = idle
                root.ram = parseInt(lines[1]) || 0
                const g = lines[2].split(",")
                root.gpuTemp = parseInt(g[0]) || 0
                root.gpuUtil = parseInt(g[1]) || 0
            }
        }
    }

    function refreshAll() {
        wifiProc.running = true
        btProc.running = true
        dndProc.running = true
        notifProc.running = true
        statsProc.running = true
    }

    Timer {
        running: root.open
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshAll()
    }
    Timer { id: refreshSoon; interval: 400; onTriggered: root.refreshAll() }

    Timer {
        running: root.open && root.player !== null && root.player.isPlaying
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    // ---------- window ----------
    PanelWindow {
        id: panel
        visible: root.open
        color: "transparent"
        anchors { top: true }
        margins { top: 52 }
        implicitWidth: 782
        implicitHeight: Math.max(leftCol.implicitHeight, rightCol.implicitHeight) + 28
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-panel"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        HyprlandFocusGrab {
            windows: [panel]
            active: root.open
            onCleared: root.open = false
        }

        Rectangle {
            anchors.fill: parent
            radius: 22
            color: Qt.alpha(c.surface, 0.60)
            border.width: 1
            border.color: Qt.alpha(c.on_surface, 0.12)

            RowLayout {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 14

                // ================= LEFT COLUMN =================
                ColumnLayout {
                    id: leftCol
                    Layout.preferredWidth: 400
                    Layout.alignment: Qt.AlignTop
                    spacing: 12

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: Qt.formatDateTime(clock.date, "HH:mm")
                            color: c.on_surface
                            font.pixelSize: 30
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: Qt.formatDateTime(clock.date, "dddd, MMM d")
                            color: Qt.alpha(c.on_surface, 0.65)
                            font.pixelSize: 13
                        }
                    }

                    // Quick toggles
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Repeater {
                            model: [
                                { label: "Wi-Fi", on: root.wifiOn, cmd: ["nmcli", "radio", "wifi", root.wifiOn ? "off" : "on"] },
                                { label: "Bluetooth", on: root.btOn, cmd: ["bluetoothctl", "power", root.btOn ? "off" : "on"] },
                                { label: "Do not disturb", on: root.dnd, cmd: ["dunstctl", "set-paused", "toggle"] }
                            ]
                            delegate: Rectangle {
                                id: tile
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredWidth: 100
                                implicitHeight: 46
                                radius: 14
                                color: tile.modelData.on ? Qt.alpha(c.primary, 0.40) : Qt.alpha(c.on_surface, 0.08)
                                border.width: 1
                                border.color: Qt.alpha(c.on_surface, 0.10)

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 1
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: tile.modelData.label
                                        color: c.on_surface
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: tile.modelData.on ? "on" : "off"
                                        color: Qt.alpha(c.on_surface, 0.65)
                                        font.pixelSize: 11
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        Quickshell.execDetached(tile.modelData.cmd)
                                        refreshSoon.restart()
                                    }
                                }
                            }
                        }
                    }

                    // Pinned apps
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Repeater {
                            model: [
                                { label: "Obsidian", cmd: ["obsidian"] },
                                { label: "Spotify", cmd: ["spotify-launcher"] },
                                { label: "Steam", cmd: ["steam"] },
                                { label: "Files", cmd: ["dolphin"] }
                            ]
                            delegate: Rectangle {
                                id: app
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredWidth: 90
                                implicitHeight: 40
                                radius: 12
                                color: appMa.containsMouse ? Qt.alpha(c.primary, 0.35) : Qt.alpha(c.on_surface, 0.08)
                                border.width: 1
                                border.color: Qt.alpha(c.on_surface, 0.10)
                                Text {
                                    anchors.centerIn: parent
                                    text: app.modelData.label
                                    color: c.on_surface
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    id: appMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        Quickshell.execDetached(app.modelData.cmd)
                                        root.open = false
                                    }
                                }
                            }
                        }
                    }

                    // Media card
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: mediaCol.implicitHeight + 24
                        radius: 16
                        color: Qt.alpha(c.on_surface, 0.07)

                        ColumnLayout {
                            id: mediaCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Rectangle {
                                    Layout.preferredWidth: 76
                                    Layout.preferredHeight: 76
                                    radius: 10
                                    color: Qt.alpha(c.on_surface, 0.10)
                                    Image {
                                        anchors.fill: parent
                                        source: root.player?.trackArtUrl ?? ""
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        Layout.fillWidth: true
                                        text: root.player?.trackTitle ?? "Nothing playing"
                                        color: c.on_surface
                                        font.pixelSize: 15
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: root.player?.trackArtist ?? ""
                                        color: Qt.alpha(c.on_surface, 0.65)
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                    RowLayout {
                                        spacing: 8
                                        Repeater {
                                            model: ["prev", root.player && root.player.isPlaying ? "pause" : "play", "next"]
                                            delegate: Rectangle {
                                                id: btn
                                                required property string modelData
                                                required property int index
                                                implicitWidth: label.implicitWidth + 24
                                                implicitHeight: 28
                                                radius: 14
                                                color: ma.containsMouse ? Qt.alpha(c.primary, 0.35) : Qt.alpha(c.on_surface, 0.10)
                                                Text {
                                                    id: label
                                                    anchors.centerIn: parent
                                                    text: btn.modelData
                                                    color: c.on_surface
                                                    font.pixelSize: 12
                                                }
                                                MouseArea {
                                                    id: ma
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: {
                                                        if (!root.player) return
                                                        if (btn.index === 0) root.player.previous()
                                                        else if (btn.index === 1) root.player.togglePlaying()
                                                        else root.player.next()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 4
                                radius: 2
                                color: Qt.alpha(c.on_surface, 0.15)
                                Rectangle {
                                    width: parent.width * (root.player && root.player.length > 0
                                        ? Math.min(1, root.player.position / root.player.length) : 0)
                                    height: parent.height
                                    radius: 2
                                    color: c.primary
                                }
                            }
                        }
                    }

                    // Volume
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: root.sink?.audio?.muted ? "mute" : "vol"
                            color: c.on_surface
                            font.pixelSize: 13
                            MouseArea {
                                anchors.fill: parent
                                onClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 24
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 6
                                radius: 3
                                color: Qt.alpha(c.on_surface, 0.15)
                                Rectangle {
                                    width: parent.width * Math.min(1, root.vol)
                                    height: parent.height
                                    radius: 3
                                    color: c.primary
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                function setFrom(x) {
                                    if (root.sink?.audio)
                                        root.sink.audio.volume = Math.max(0, Math.min(1, x / width))
                                }
                                onPressed: mouse => setFrom(mouse.x)
                                onPositionChanged: mouse => setFrom(mouse.x)
                            }
                        }

                        Text {
                            text: Math.round(root.vol * 100) + "%"
                            color: Qt.alpha(c.on_surface, 0.65)
                            font.pixelSize: 13
                            Layout.preferredWidth: 38
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    // System stats
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Repeater {
                            model: [
                                { l: "CPU", v: root.cpu + "%" },
                                { l: "RAM", v: root.ram + "%" },
                                { l: "GPU", v: root.gpuTemp > 0 ? root.gpuTemp + "°C" : "--" }
                            ]
                            delegate: Rectangle {
                                id: stat
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredWidth: 100
                                implicitHeight: 52
                                radius: 14
                                color: Qt.alpha(c.on_surface, 0.07)
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: stat.modelData.v
                                        color: c.on_surface
                                        font.pixelSize: 16
                                        font.bold: true
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: stat.modelData.l
                                        color: Qt.alpha(c.on_surface, 0.60)
                                        font.pixelSize: 11
                                    }
                                }
                            }
                        }
                    }

                    // Power row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Repeater {
                            model: [
                                { label: "Sleep", cmd: ["systemctl", "suspend"], confirm: false },
                                { label: "Log out", cmd: ["sh", "-c", "hyprctl dispatch 'hl.dsp.exit()'"], confirm: true },
                                { label: "Reboot", cmd: ["systemctl", "reboot"], confirm: true },
                                { label: "Shut down", cmd: ["systemctl", "poweroff"], confirm: true }
                            ]
                            delegate: Rectangle {
                                id: pbtn
                                required property var modelData
                                property bool armed: false
                                Layout.fillWidth: true
                                Layout.preferredWidth: 90
                                implicitHeight: 36
                                radius: 12
                                color: pbtn.armed ? Qt.rgba(0.9, 0.3, 0.3, 0.50)
                                    : (pMa.containsMouse ? Qt.alpha(c.primary, 0.30) : Qt.alpha(c.on_surface, 0.08))
                                border.width: 1
                                border.color: Qt.alpha(c.on_surface, 0.10)

                                Timer { id: disarm; interval: 3000; onTriggered: pbtn.armed = false }

                                Text {
                                    anchors.centerIn: parent
                                    text: pbtn.armed ? "Confirm?" : pbtn.modelData.label
                                    color: c.on_surface
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    id: pMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        if (!pbtn.modelData.confirm || pbtn.armed) {
                                            pbtn.armed = false
                                            root.open = false
                                            Quickshell.execDetached(pbtn.modelData.cmd)
                                        } else {
                                            pbtn.armed = true
                                            disarm.restart()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ================= RIGHT COLUMN =================
                ColumnLayout {
                    id: rightCol
                    Layout.preferredWidth: 340
                    Layout.alignment: Qt.AlignTop
                    spacing: 12

                    // Calendar
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: calCol.implicitHeight + 24
                        radius: 16
                        color: Qt.alpha(c.on_surface, 0.07)

                        ColumnLayout {
                            id: calCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: 14
                                    color: prevMa.containsMouse ? Qt.alpha(c.primary, 0.35) : Qt.alpha(c.on_surface, 0.08)
                                    Text { anchors.centerIn: parent; text: "<"; color: c.on_surface; font.pixelSize: 13 }
                                    MouseArea {
                                        id: prevMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.viewDate = new Date(root.viewDate.getFullYear(), root.viewDate.getMonth() - 1, 1)
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: Qt.formatDateTime(root.viewDate, "MMMM yyyy")
                                    color: c.on_surface
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                                Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: 14
                                    color: nextMa.containsMouse ? Qt.alpha(c.primary, 0.35) : Qt.alpha(c.on_surface, 0.08)
                                    Text { anchors.centerIn: parent; text: ">"; color: c.on_surface; font.pixelSize: 13 }
                                    MouseArea {
                                        id: nextMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.viewDate = new Date(root.viewDate.getFullYear(), root.viewDate.getMonth() + 1, 1)
                                    }
                                }
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 7
                                columnSpacing: 2
                                rowSpacing: 2

                                Repeater {
                                    model: ["S", "M", "T", "W", "T", "F", "S"]
                                    delegate: Text {
                                        required property string modelData
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 40
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData
                                        color: Qt.alpha(c.on_surface, 0.50)
                                        font.pixelSize: 11
                                    }
                                }
                                Repeater {
                                    model: root.cells
                                    delegate: Rectangle {
                                        id: dayCell
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 40
                                        implicitHeight: 28
                                        radius: 9
                                        color: dayCell.modelData.today ? c.primary : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: dayCell.modelData.day
                                            font.pixelSize: 12
                                            color: dayCell.modelData.today ? c.on_primary
                                                : Qt.alpha(c.on_surface, dayCell.modelData.inMonth ? 0.90 : 0.28)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Notifications
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: notifCol.implicitHeight + 24
                        radius: 16
                        color: Qt.alpha(c.on_surface, 0.07)

                        ColumnLayout {
                            id: notifCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: "Notifications"
                                    color: c.on_surface
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                                Rectangle {
                                    implicitWidth: clearLabel.implicitWidth + 20
                                    implicitHeight: 24
                                    radius: 12
                                    color: clrMa.containsMouse ? Qt.alpha(c.primary, 0.35) : Qt.alpha(c.on_surface, 0.08)
                                    Text { id: clearLabel; anchors.centerIn: parent; text: "Clear all"; color: c.on_surface; font.pixelSize: 11 }
                                    MouseArea {
                                        id: clrMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            Quickshell.execDetached(["dunstctl", "history-clear"])
                                            refreshSoon.restart()
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: root.notifs.length === 0
                                text: "Nothing new"
                                color: Qt.alpha(c.on_surface, 0.50)
                                font.pixelSize: 12
                            }

                            Repeater {
                                model: root.notifs.slice(0, 4)
                                delegate: Rectangle {
                                    id: note
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: noteCol.implicitHeight + 14
                                    radius: 10
                                    color: Qt.alpha(c.on_surface, 0.06)

                                    ColumnLayout {
                                        id: noteCol
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        anchors.right: parent.right
                                        anchors.rightMargin: 28
                                        anchors.top: parent.top
                                        anchors.topMargin: 7
                                        spacing: 1
                                        Text {
                                            Layout.fillWidth: true
                                            text: note.modelData.summary !== "" ? note.modelData.summary : note.modelData.app
                                            textFormat: Text.PlainText
                                            color: c.on_surface
                                            font.pixelSize: 12
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            visible: note.modelData.body !== ""
                                            text: note.modelData.body
                                            textFormat: Text.PlainText
                                            color: Qt.alpha(c.on_surface, 0.65)
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        anchors.top: parent.top
                                        anchors.topMargin: 6
                                        text: "x"
                                        color: Qt.alpha(c.on_surface, 0.55)
                                        font.pixelSize: 12
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -6
                                            onClicked: {
                                                Quickshell.execDetached(["dunstctl", "history-rm", String(note.modelData.id)])
                                                refreshSoon.restart()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

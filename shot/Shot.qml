import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../themes"

Item {
    id: root
    property bool opened: false
    property var scr: null

    readonly property var modes: ["region", "window", "screen"]
    readonly property var dirs: ["ss", "kl", "mpv"]

    property int mode: 0
    property int dirIdx: 0

    property rect drag: Qt.rect(0, 0, 0, 0)
    property real mx: 0
    property real my: 0

    property string frozenPath: ""
    property var wins: []

    function fade(color, opacity) { return Qt.rgba(color.r, color.g, color.b, opacity) }

    readonly property var hover: {
        if (mode !== 1) return null
        const scale = scr?.devicePixelRatio ?? 1
        const globalX = scr.x + mx * scale
        const globalY = scr.y + my * scale
        return wins.find(w => globalX >= w.x && globalX < w.x + w.w && globalY >= w.y && globalY < w.y + w.h) ?? null
    }

    readonly property rect sel: {
        const scale = scr?.devicePixelRatio ?? 1
        if (mode === 2) return Qt.rect(0, 0, stage.width, stage.height)
        if (mode === 1) return hover ? Qt.rect((hover.x - scr.x) / scale, (hover.y - scr.y) / scale, hover.w / scale, hover.h / scale) : Qt.rect(0, 0, 0, 0)
        return drag.width > 0 ? drag : Qt.rect(0, 0, 0, 0)
    }

    function open() {
        if (win.visible) return
        const mon = Hyprland.focusedMonitor
        scr = Quickshell.screens.find(s => s.name === mon?.name) ?? Quickshell.screens[0]
        Hyprland.refreshToplevels()
        wins = Hyprland.toplevels.values.filter(t => t.workspace?.id === mon?.activeWorkspace?.id && t.lastIpcObject?.size)
            .map(t => ({ x: t.lastIpcObject.at[0], y: t.lastIpcObject.at[1], w: t.lastIpcObject.size[0], h: t.lastIpcObject.size[1] }))
        drag = Qt.rect(0, 0, 0, 0)
        frozenPath = Quickshell.env("XDG_RUNTIME_DIR") + "/tzeuk-frozen-" + Date.now() + ".ppm"
        freezeProc.command = ["bash", "-c", `grim -t ppm -o "${scr.name}" "${frozenPath}"`]
        freezeProc.running = true
    }

    function close() { win.visible = false }

    function fire() {
        if (sel.width < 2 || sel.height < 2) return
        const scale = scr?.devicePixelRatio ?? 1
        const x = Math.round(scr.x + sel.x * scale)
        const y = Math.round(scr.y + sel.y * scale)
        const w = Math.round(sel.width * scale)
        const h = Math.round(sel.height * scale)
        const geom = `${w}x${h}+${x}+${y}`
        const dirName = root.dirs[root.dirIdx]
        const dirPath = Quickshell.env("HOME") + "/pix/ss" + (dirName === "ss" ? "" : "/" + dirName)
        win.visible = false
        Quickshell.execDetached(["bash", "-c", `mkdir -p "${dirPath}" && FILE="${dirPath}/shot-$(date +%F_%H-%M-%S).png" && grim -g "${geom}" "$FILE" && cat "$FILE" | wl-copy -t image/png && notify-send -a "tzeuk" "Snapshot" "Saved to ${dirName} & copied"`])
    }

    Process {
        id: freezeProc
        stdout: StdioCollector {
            onStreamFinished: { win.visible = true; stage.forceActiveFocus() }
        }
    }

    PanelWindow {
        id: win
        visible: false
        screen: root.scr
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "tzeuk-shot"

        FocusScope {
            id: stage
            anchors.fill: parent
            focus: true
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape) root.close()
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.fire()
                else if (e.key === Qt.Key_Tab) root.mode = (root.mode + 1) % 3
                else if (e.key === Qt.Key_D) root.dirIdx = (root.dirIdx + 1) % 3
                else return
                e.accepted = true
            }

            Image { id: frozenImg; visible: false; source: root.frozenPath ? "file://" + root.frozenPath : ""; cache: false }

            Item {
                anchors.fill: parent
                readonly property color c: fade(Theme.bg, 0.74)
                readonly property rect r: root.sel.width ? root.sel : Qt.rect(0, 0, 0, 0)
                Rectangle { width: parent.width; height: Math.max(0, r.y); color: parent.c }
                Rectangle { y: r.y + r.height; width: parent.width; height: Math.max(0, parent.height - y); color: parent.c }
                Rectangle { y: r.y; width: Math.max(0, r.x); height: r.height; color: parent.c }
                Rectangle { x: r.x + r.width; y: r.y; width: Math.max(0, parent.width - x); height: r.height; color: parent.c }
            }

            Canvas {
                anchors.fill: parent
                visible: root.mode === 0 && root.drag.width === 0
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset(); ctx.strokeStyle = fade(Theme.fg, 0.5); ctx.setLineDash([4, 4])
                    ctx.beginPath(); ctx.moveTo(root.mx, 0); ctx.lineTo(root.mx, height)
                    ctx.moveTo(0, root.my); ctx.lineTo(width, root.my); ctx.stroke()
                }
                Connections { target: root; function onMxChanged() { parent.requestPaint() } function onMyChanged() { parent.requestPaint() } }
            }

            Item {
                visible: root.sel.width > 0; x: root.sel.x; y: root.sel.y; width: root.sel.width; height: root.sel.height
                Rectangle { anchors.fill: parent; color: "transparent"; border { width: 1; color: Theme.fg } }
                Repeater {
                    model: 4
                    Rectangle {
                        required property int index
                        x: (index % 2 ? parent.width : 0) - 6; y: (index > 1 ? parent.height : 0) - 6
                        width: 12; height: 12; radius: 6; color: Theme.fg
                    }
                }
                Item {
                    y: -30; width: dims.width; height: dims.height
                    Row {
                        id: dims; spacing: 10
                        Text { text: modes[mode]; font.family: Theme.fontMono; font.pixelSize: 11; color: Theme.fg }
                        Text { text: `${Math.round(root.sel.width)}×${Math.round(root.sel.height)}`; font.family: Theme.fontDoto; font.weight: Font.Black; font.pixelSize: 14; color: Theme.fg }
                    }
                }
            }

            Item {
                id: loupe
                visible: root.mode === 0 && root.drag.width === 0
                readonly property int zoom: 12
                readonly property real scale: root.scr?.devicePixelRatio ?? 1
                readonly property int px: Math.floor(root.mx * scale)
                readonly property int py: Math.floor(root.my * scale)
                x: root.mx + 24 + width > stage.width ? root.mx - 24 - width : root.mx + 24
                y: root.my + 24 + height > stage.height ? root.my - 24 - height : root.my + 24
                width: 180; height: 240

                Rectangle { x: 6; y: 6; width: 168; height: 168; radius: 84; color: Theme.bg }
                Item {
                    x: 12; y: 12; width: 13 * loupe.zoom; height: 13 * loupe.zoom
                    Image {
                        source: frozenImg.source; smooth: false
                        width: frozenImg.sourceSize.width * loupe.zoom; height: frozenImg.sourceSize.height * loupe.zoom
                        x: (6 - loupe.px) * loupe.zoom; y: (6 - loupe.py) * loupe.zoom
                    }
                }
                Rectangle { x: 80; y: 80; width: 20; height: 20; radius: 10; color: "transparent"; border { width: 1.5; color: Theme.fg } }

                // Standard Repeater replacing the custom Ring component
                Repeater {
                    model: 48
                    Rectangle {
                        width: 3; height: 3; radius: 1.5; color: Theme.nText
                        property real angle: (index / 48) * Math.PI * 2
                        property real r: (180 / 2) - (3 / 2) - 2
                        x: (180 / 2) + r * Math.cos(angle) - 1.5
                        y: (180 / 2) + r * Math.sin(angle) - 1.5
                    }
                }

                Canvas {
                    id: picker; property string hex: "#000000"; visible: false; width: 1; height: 1
                    onPaint: {
                        if (frozenImg.status !== Image.Ready) return
                        var ctx = getContext("2d"); ctx.drawImage(frozenImg, loupe.px, loupe.py, 1, 1, 0, 0, 1, 1)
                        var d = ctx.getImageData(0, 0, 1, 1).data
                        hex = "#" + [d[0], d[1], d[2]].map(v => v.toString(16).padStart(2, "0")).join("").toUpperCase()
                    }
                    Connections { target: loupe; function onPxChanged() { picker.requestPaint() } function onPyChanged() { picker.requestPaint() } }
                }

                Rectangle {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                    width: infoRow.width + 36; height: 44; radius: 22
                    color: Theme.surfaceHi; border { width: 1; color: Theme.line }
                    Row {
                        id: infoRow; anchors.centerIn: parent; spacing: 12
                        Text { anchors.verticalCenter: parent.verticalCenter; text: `${Math.round(root.mx)} · ${Math.round(root.my)}`; font.family: Theme.fontDoto; font.weight: Font.Black; font.pixelSize: 20; color: Theme.fg }
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; radius: 6; color: picker.hex; border { width: 1; color: Theme.line } }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: picker.hex; font.family: Theme.fontMono; font.pixelSize: 11; color: Theme.nText }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.CrossCursor; property point from
                onPositionChanged: e => {
                    root.mx = e.x; root.my = e.y
                    if (pressed && root.mode === 0) root.drag = Qt.rect(Math.min(from.x, e.x), Math.min(from.y, e.y), Math.abs(e.x - from.x), Math.abs(e.y - from.y))
                }
                onPressed: e => {
                    if (root.mode === 1 || root.mode === 2) return root.fire()
                    from = Qt.point(e.x, e.y); root.drag = Qt.rect(e.x, e.y, 0, 0)
                }
            }

            Column {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 44 }
                spacing: 12
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: pillRow.width + 40; height: 56; radius: 28
                    color: Theme.surfaceHi; border { width: 1; color: Theme.line }
                    Row {
                        id: pillRow; anchors.centerIn: parent; spacing: 6
                        Repeater {
                            model: root.modes
                            delegate: Rectangle {
                                required property string modelData; required property int index
                                width: txt.width + 24; height: 36; radius: 18
                                color: index === root.mode ? Theme.fg : "transparent"
                                Text {
                                    id: txt; anchors.centerIn: parent; text: modelData
                                    font.family: Theme.fontMono; font.pixelSize: 11
                                    color: index === root.mode ? Theme.bg : Theme.nText
                                }
                                TapHandler { onTapped: root.mode = index }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                            }
                        }
                        Item { width: 18; height: 36; Rectangle { anchors.centerIn: parent; width: 4; height: 4; radius: 2; color: Theme.nText } }
                        Rectangle {
                            width: txt2.width + 24; height: 36; radius: 18
                            color: Theme.accent
                            Text {
                                id: txt2; anchors.centerIn: parent; text: root.dirs[root.dirIdx]
                                font.family: Theme.fontMono; font.pixelSize: 11; color: Theme.bg
                            }
                            TapHandler { onTapped: root.dirIdx = (root.dirIdx + 1) % 3 }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: hintRow.width + 44; height: 36; radius: 18
                    color: Theme.surfaceHi; border { width: 1; color: Theme.line }
                    Row {
                        id: hintRow; anchors.centerIn: parent; spacing: 28
                        Repeater {
                            model: ["drag select", "tab mode", "d dir", "↵ capture", "esc cancel"]
                            delegate: Text {
                                required property string modelData; text: modelData
                                font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.nText
                            }
                        }
                    }
                }
            }
        }
    }
}

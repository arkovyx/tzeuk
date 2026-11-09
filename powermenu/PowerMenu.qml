import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "."
import "../glyphs"
import "../themes"

PanelWindow {
    id: win
    property bool opened: false
    signal closeRequested()

    // ── Uptime ──
    property real uptime: 0

    Process {
        id: uptimeProc
        command: ["cat", "/proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(" ")
                if (parts.length > 0) win.uptime = parseFloat(parts[0]) || 0
            }
        }
    }

    Timer {
        interval: 30000
        running: win.opened
        repeat: true
        triggeredOnStart: true
        onTriggered: uptimeProc.running = true
    }

    // ── Actions ──
    readonly property var actions: [
        { id: "lock",       label: "Lock",       confirm: false },
        { id: "logout",     label: "Log Out",    confirm: false },
        { id: "suspend",    label: "Suspend",    confirm: false },
        { id: "reboot",     label: "Reboot",     confirm: true  },
        { id: "shutdown",   label: "Shut Down",  confirm: true  },
        { id: "screen-off", label: "Screen Off", confirm: false },
        { id: "cancel",     label: "Cancel",     confirm: false }
    ]

    function runAction(id) {
        switch (id) {
        case "lock":       Quickshell.execDetached(["hyprlock"]); break
        case "logout":     Quickshell.execDetached(["hyprctl", "dispatch", "exit"]); break
        case "suspend":    Quickshell.execDetached(["systemctl", "suspend"]); break
        case "reboot":     Quickshell.execDetached(["systemctl", "reboot"]); break
        case "shutdown":   Quickshell.execDetached(["systemctl", "poweroff"]); break
        case "screen-off": Quickshell.execDetached(["hyprctl", "dispatch", "dpms", "off"]); break
        case "cancel":
        default: break
        }
    }

    // ── Animation ──
    property real t: opened ? 1 : 0
    Behavior on t {
        NumberAnimation {
            duration: Theme.t
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.glide
        }
    }

    visible: t > 0
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tzeuk-power"
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property var words: ({
        lock: "lock",
        logout: "log out",
        suspend: "suspend",
        reboot: "reboot",
        shutdown: "shut down",
        "screen-off": "screen off",
        cancel: "cancel"
    })
    function word(a) {
        if (!a) return ""
        return words[a.id] || a.label || ""
    }

    property int current: 0
    property string armed: ""
    Timer { id: disarm; interval: 3000; onTriggered: win.armed = "" }

    // ── Fuzzy (inline) ──
    function fuzzyScore(str, query) {
        if (!query || query === "") return 1
        if (!str) return 0
        var s = String(str).toLowerCase()
        var q = String(query).toLowerCase()
        if (s === q) return 1000
        if (s.indexOf(q) === 0) return 800
        if (s.indexOf(" " + q) >= 0 || s.indexOf("-" + q) >= 0) return 600
        if (s.indexOf(q) >= 0) return 400
        var i = 0
        for (var j = 0; j < s.length && i < q.length; j++)
            if (s[j] === q[i]) i++
        return i === q.length ? 100 : 0
    }

    property var shown: actions

    function recomputeShown() {
        var q = (filter.text || "").toLowerCase().trim()
        if (q === "") { shown = actions; return }
        var out = []
        for (var i = 0; i < actions.length; i++) {
            var sc = Math.max(
                fuzzyScore(actions[i].label, q),
                fuzzyScore(word(actions[i]), q)
            )
            if (sc > 0) out.push({ a: actions[i], sc: sc, i: i })
        }
        out.sort(function (x, y) { return y.sc - x.sc || x.i - y.i })
        var res = []
        for (var j = 0; j < out.length; j++) res.push(out[j].a)
        shown = res.length > 0 ? res : []
    }

    Component.onCompleted: recomputeShown()

    onOpenedChanged: {
        if (!opened) return
        filter.text = ""
        recomputeShown()
        var idx = -1
        for (var i = 0; i < shown.length; i++) {
            if (shown[i].id === "cancel") { idx = i; break }
        }
        current = idx >= 0 ? idx : Math.max(0, shown.length - 1)
        armed = ""
        Qt.callLater(() => filter.forceActiveFocus())
    }

    function trigger(i) {
        var a = shown[i]
        if (!a) return
        current = i
        if (a.confirm && armed !== a.id) { armed = a.id; disarm.restart(); return }
        armed = ""
        closeRequested()
        runAction(a.id)
    }

    Shortcut {
        sequence: "Escape"
        enabled: win.opened
        onActivated: win.closeRequested()
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.fade(Theme.bg, 0.96)
        opacity: win.t
        MouseArea { anchors.fill: parent; onClicked: win.closeRequested() }
    }

    TextInput {
        id: filter
        width: 1
        height: 1
        opacity: 0
        onTextChanged: { win.recomputeShown(); win.current = 0; win.armed = "" }
        Keys.onEscapePressed: win.closeRequested()
        Keys.onReturnPressed: win.trigger(win.current)
        Keys.onEnterPressed: win.trigger(win.current)
        Keys.onPressed: event => {
            var n = win.shown.length
            if (!n) return
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                win.current = (win.current + 1) % n
                win.armed = ""
                event.accepted = true
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                win.current = (win.current + n - 1) % n
                win.armed = ""
                event.accepted = true
            }
        }
    }

    Item {
        id: stage
        readonly property real s: Math.min(win.width / 1920, win.height / 1080)
        width: win.width / s
        height: win.height / s
        scale: s
        transformOrigin: Item.TopLeft
        opacity: win.t

        Lb {
            x: 240
            y: 90
            px: 14
            color: filter.text !== "" ? Theme.fg : Theme.fade(Theme.fg, 0.35)
            text: filter.text !== ""
                ? "filter · " + filter.text + (win.shown.length ? "" : " · no match")
                : "filter · start typing"
        }

        Column {
            x: 240 - 30 * (1 - win.t)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 20

            Repeater {
                model: win.shown
                Row {
                    id: it
                    required property var modelData
                    required property int index
                    readonly property bool on: win.current === index
                    readonly property bool isArmed: win.armed === modelData.id
                    spacing: 30

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: it.on
                        width: 30
                        height: 30
                        radius: 15
                        color: it.isArmed ? Theme.err : Theme.live
                    }
                    Num {
                        text: win.word(it.modelData).toUpperCase()
                        font.pixelSize: it.on ? 128 : 56
                        color: it.isArmed ? Theme.err : it.on ? Theme.fg : Theme.mute
                    }
                    Lb {
                        visible: it.isArmed
                        anchors.verticalCenter: parent.verticalCenter
                        px: 14
                        color: Theme.err
                        text: "↵ again to " + win.word(it.modelData)
                    }
                    HoverHandler {
                        onHoveredChanged: if (hovered && win.current !== it.index) {
                            win.current = it.index
                            win.armed = ""
                        }
                    }
                    TapHandler { onTapped: win.trigger(it.index) }
                }
            }
        }

        Item {
            x: stage.width - 200 - 440
            anchors.verticalCenter: parent.verticalCenter
            width: 440
            height: 440

            Ring {
                anchors.fill: parent
                n: 60
                dot: 10
                f: (win.uptime % 86400) / 86400
                activeColor: Theme.live
                idleColor: Theme.fade(Theme.fg, 0.15)
            }

            Column {
                anchors.centerIn: parent

                Lb {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "uptime"
                    color: Theme.mute
                }
                Num {
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: lead + 10
                    bottomPadding: lead + 10
                    text: Math.floor(win.uptime / 3600) + ":" +
                          ("0" + Math.floor(win.uptime / 60) % 60).slice(-2)
                    font.pixelSize: 104
                    color: Theme.fg
                }
                Lb {
                    anchors.horizontalCenter: parent.horizontalCenter
                    readonly property int n: Hyprland.toplevels.values.length
                    text: n + (n === 1 ? " window open" : " windows open")
                    color: Theme.mute
                }
            }
        }

        Row {
            x: 240
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 70
            spacing: 34

            Lb { text: "↑↓ select";      color: Theme.mute }
            Lb { text: "↵ confirm";      color: Theme.mute }
            Lb { text: "type to filter"; color: Theme.mute }
            Lb { text: "esc cancel";     color: Theme.mute }
        }
    }
}

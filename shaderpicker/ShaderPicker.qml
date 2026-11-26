
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../themes"
import "../glyphs"
import "../wallpicker"

// Shader picker in the wallpicker's style. Drop-in: same API as before (opened / closeRequested), same state file.
// The desktop itself is the preview: browsing applies the shader live (debounced), ↵ keeps it, esc puts the old one back.
// Hyprland screen shaders exist only inside the compositor, so there is no way to render them in QML; that is why the
// preview is the real screen, and the picker is shaded too while a shader is on.
//
// Keys (normal): ←→ ↑↓ h l j k browse · ↵ / space apply · p live preview on/off · i or / filter · g / G first / last · esc cancel
// Keys (insert): type to filter · ←→ browse · ↵ apply · esc normal
PanelWindow {
    id: win

    property bool opened: false
    signal closeRequested()

    readonly property string stateFile: Quickshell.env("HOME") + "/.cache/tzeuk/shader"

    readonly property string fDot:  Theme.fontDoto !== "" ? Theme.fontDoto : "monospace"
    readonly property string fMono: Theme.fontMono !== "" ? Theme.fontMono : "monospace"
    readonly property string fSans: Theme.fontSans !== "" ? Theme.fontSans : "sans-serif"
    function dim(a) { return Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, a) }
    function fade(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function pad2(n) { return String(n).padStart(2, "0") }

    // ── state ──
    property string mode: "normal"      // "normal" | "insert"
    property string query: ""
    property var shaders: []
    property int sel: 0
    property bool live: true            // apply while browsing
    property bool ready: false          // scan finished
    property bool committed: false
    property string original: ""        // what was active when the picker opened
    property string current: ""         // what is kept (the red dot)
    property string liveName: ""        // what is applied right now

    function pretty(n) { return n.replace(/^\d+_/, "").replace(/_/g, " ") }
    function badge(it) {
        if (it.isNone) return "off"
        const m = /^(\d+)_/.exec(it.name)
        return m ? m[1] : it.name
    }
    function description(name) {
        const desc = {
            "none": "Disable all shaders",
            "dots": "Screen-wide dot matrix via Hyprland",
            "wall": "Wallpaper LED dots via Quickshell",
            "01_sepia": "Warm sepia tone filter",
            "02_grayscale": "Black and white rendering",
            "03_vibrance": "Enhanced color saturation",
            "04_optics_compensate": "Optical distortion correction",
            "05_sketch": "Pencil sketch effect",
            "06_chromatic_aberration": "Lens color fringing",
            "07_newspaper": "Newspaper print dithering",
            "08_posterization": "Retro poster colors",
            "09_anaglyph_3d": "3D anaglyph effect"
        }
        return desc[name] || "Custom shader"
    }
    function typeOf(n) {
        if (n === "" || n === "none") return "none"
        for (let i = 0; i < shaders.length; i++) if (shaders[i].name === n) return shaders[i].type
        return "hyprland"
    }

    readonly property var items: {
        const out = [{ name: "none", state: "", type: "none", isNone: true }]
        for (let i = 0; i < shaders.length; i++) {
            const s = shaders[i]
            if (query && s.name.toLowerCase().indexOf(query) < 0) continue
            out.push({ name: s.name, state: s.name, type: s.type, isNone: false })
        }
        return out
    }
    readonly property var selItem: items[sel] || null
    readonly property string selState: selItem ? selItem.state : ""

    function clampSel() { sel = Math.max(0, Math.min(items.length - 1, sel)) }
    onItemsChanged: clampSel()
    function go(d) { sel = Math.max(0, Math.min(items.length - 1, sel + d)) }
    function selectDefault() {
        if (query === "") {
            for (let i = 0; i < items.length; i++) if (items[i].state === current) { sel = i; return }
            sel = 0
        } else {
            sel = items.length > 1 ? 1 : 0
        }
    }

    // ── apply ──
    // Quickshell-side shaders (wall) just watch the state file; Hyprland ones need a reload, also when switching away from one.
    function applyShader(name) {
        const reload = typeOf(liveName) === "hyprland" || typeOf(name) === "hyprland"
        liveName = name
        Quickshell.execDetached(["bash", "-c",
            'mkdir -p "$(dirname "$2")"; printf "%s" "$1" > "$2"; if [ "$3" = 1 ]; then sleep 0.05; hyprctl reload; fi',
            "shader", name, stateFile, reload ? "1" : "0"])
    }
    function commit() {
        if (!selItem) return
        if (selState !== liveName) applyShader(selState)
        current = selState
        committed = true
        closeRequested()
    }
    function setLive(v) {
        live = v
        if (live) settle.restart()
        else {
            settle.stop()
            if (liveName !== original) applyShader(original)   // browsing no longer previews: back to the old one
        }
    }

    onSelStateChanged: if (opened && ready && live) settle.restart()
    Timer {
        id: settle
        interval: 450
        onTriggered: if (win.opened && win.ready && win.live && win.selState !== win.liveName) win.applyShader(win.selState)
    }

    FileView {
        id: stateView
        path: win.stateFile
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }

    Process {
        id: scanProc
        command: ["bash", "-c", `
echo "dots|hyprland|$HOME/.config/quickshell/tzeuk/shaders/hyprland/screen-dots.frag"
echo "wall|quickshell|$HOME/.config/quickshell/tzeuk/shaders/wall.frag.qsb"
for f in "$HOME"/.config/hypr/shaders/*.glsl; do [ -f "$f" ] && echo "$(basename "$f" .glsl)|hyprland|$f"; done
true
`]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0)
                const out = []
                for (let i = 0; i < lines.length; i++) {
                    const p = lines[i].split("|")
                    if (p.length < 3) continue
                    out.push({ name: p[0], type: p[1], path: p[2] })
                }
                win.shaders = out
                win.selectDefault()
                win.ready = true
            }
        }
    }

    onOpenedChanged: {
        if (opened) {
            let cur = ""
            try { stateView.reload(); cur = stateView.text().trim() } catch (e) { cur = "" }
            original = cur
            current = cur
            liveName = cur
            committed = false
            ready = false
            mode = "normal"
            query = ""
            searchInput.text = ""
            sel = 0
            scanProc.running = true
            Qt.callLater(() => searchInput.forceActiveFocus())
        } else {
            settle.stop()
            if (!committed && liveName !== original) applyShader(original)   // cancelled: put the old shader back
        }
    }

    // ── keyboard ──
    function handleKey(event) {
        const shift = (event.modifiers & Qt.ShiftModifier) !== 0
        event.accepted = true

        if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) { go(-1); return }
        if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) { go(1); return }
        if (event.key === Qt.Key_PageUp) { go(-5); return }
        if (event.key === Qt.Key_PageDown) { go(5); return }
        if (event.key === Qt.Key_Home) { sel = 0; return }
        if (event.key === Qt.Key_End) { sel = items.length - 1; return }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { commit(); return }

        if (mode === "insert") {
            if (event.key === Qt.Key_Escape) { mode = "normal"; return }
            event.accepted = false
            return
        }

        switch (event.key) {
        case Qt.Key_Escape:
            if (query !== "") searchInput.text = ""
            else closeRequested()
            break
        case Qt.Key_I:
        case Qt.Key_Slash:
            mode = "insert"
            searchInput.forceActiveFocus()
            break
        case Qt.Key_H:
        case Qt.Key_K:
            go(-1)
            break
        case Qt.Key_L:
        case Qt.Key_J:
            go(1)
            break
        case Qt.Key_G:
            sel = shift ? items.length - 1 : 0
            break
        case Qt.Key_P:
            setLive(!live)
            break
        case Qt.Key_Space:
            commit()
            break
        }
    }

    // ── window ──
    property real t: opened ? 1 : 0
    Behavior on t { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] } }
    property real pos: sel
    Behavior on pos { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] } }

    function size(d) { d = Math.abs(d); return d < 1 ? 190 - 62 * d : Math.max(64, 128 - (d - 1) * 12) }
    readonly property var at: {
        const a = [0]
        for (let k = 1; k <= 10; k++) a.push(a[k - 1] + (size(k - 1) + size(k)) / 2 + (k === 1 ? 44 : 22))
        return a
    }
    function off(d) {
        const a = Math.min(Math.abs(d), 9), k = Math.floor(a), x = at[k] + (at[k + 1] - at[k]) * (a - k)
        return d < 0 ? -x : x
    }

    visible: t > 0
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tzeuk-shader"
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Item {
        id: stage
        readonly property real u: win.height / 1080
        width: win.width / u
        height: win.height / u
        scale: u
        transformOrigin: Item.TopLeft
        opacity: win.t

        // the middle stays clear: the live desktop is the preview. Only top and bottom fade in for the labels
        MouseArea {
            anchors.fill: parent
            property real acc: 0
            onClicked: searchInput.forceActiveFocus()
            onWheel: w => {
                acc += w.angleDelta.y || w.angleDelta.x
                while (Math.abs(acc) >= 120) {
                    win.go(acc > 0 ? -1 : 1)
                    acc -= Math.sign(acc) * 120
                }
            }
        }
        Rectangle {
            width: parent.width
            height: 380
            gradient: Gradient {
                GradientStop { position: 0; color: win.fade(Theme.bg, 0.85) }
                GradientStop { position: 1; color: win.fade(Theme.bg, 0) }
            }
        }
        Rectangle {
            y: parent.height - height
            width: parent.width
            height: 460
            gradient: Gradient {
                GradientStop { position: 0; color: win.fade(Theme.bg, 0) }
                GradientStop { position: 1; color: win.fade(Theme.bg, 0.9) }
            }
        }

        // counter, name, description
        Column {
            x: 150 - 30 * (1 - win.t)
            y: 110

            Cap { text: "shader · " + win.shaders.length + " available" }
            Row {
                topPadding: 18
                spacing: 10
                Dot { id: idx; text: win.pad2(win.items.length === 0 ? 0 : win.sel + 1); font.pixelSize: 150 }
                Dot { anchors.baseline: idx.baseline; text: "/" + win.pad2(win.items.length); font.pixelSize: 54; color: win.dim(0.35) }
            }
            Cap {
                topPadding: 22
                width: 700
                elide: Text.ElideRight
                text: win.selItem ? (win.selItem.isNone ? "none" : win.pretty(win.selItem.name)) : ""
                px: 14
                color: Theme.fg
            }
            Cap {
                topPadding: 10
                width: 700
                elide: Text.ElideRight
                text: win.selItem ? win.description(win.selItem.name) : ""
                px: 11
            }
            Cap {
                topPadding: 8
                text: !win.selItem ? ""
                    : win.selItem.type === "hyprland" ? "screen shader · hyprland"
                    : win.selItem.type === "quickshell" ? "wallpaper shader · quickshell"
                    : "no shader"
                px: 10
                color: win.dim(0.35)
            }
        }

        // filter + live toggle
        Column {
            anchors { right: parent.right; rightMargin: 150 - 30 * (1 - win.t) }
            y: 110
            spacing: 26

            Rectangle {
                id: searchBox
                anchors.right: parent.right
                width: 460
                height: 42
                radius: 21
                color: "transparent"
                border.width: 1
                border.color: win.mode === "insert" ? Theme.fg
                    : (searchBoxHover.containsMouse ? win.dim(0.55) : win.dim(0.25))
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Text {
                    id: prompt
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: "/"
                    color: Theme.accent
                    font.family: win.fDot
                    font.weight: Font.Black
                    font.pixelSize: 20
                }

                Rectangle {
                    id: modeBadge
                    z: 101
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 76; height: 26; radius: 13
                    color: win.mode === "insert"
                        ? (modeBadgeHover.containsMouse ? win.fade(Theme.accent, 0.15) : "transparent")
                        : Theme.fg
                    border.width: win.mode === "insert" ? 1 : 0
                    border.color: Theme.accent
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: win.mode === "insert" ? "INSERT" : "NORMAL"
                        color: win.mode === "insert" ? Theme.accent : Theme.bg
                        font.family: win.fMono
                        font.pixelSize: 10
                        font.letterSpacing: 1
                    }
                    MouseArea {
                        id: modeBadgeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            win.mode = win.mode === "insert" ? "normal" : "insert"
                            if (win.mode === "insert") searchInput.forceActiveFocus()
                        }
                    }
                }

                TextInput {
                    id: searchInput
                    z: 1
                    anchors.left: prompt.right
                    anchors.leftMargin: 10
                    anchors.right: modeBadge.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.fg
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.fg
                    font.family: win.fSans
                    font.pixelSize: 15
                    clip: true
                    readOnly: win.mode === "normal"
                    inputMethodHints: Qt.ImhNoPredictiveText

                    onTextChanged: {
                        win.query = text.toLowerCase()
                        win.selectDefault()
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: searchInput.text.length === 0
                        text: "FILTER BY NAME..."
                        color: win.dim(0.4)
                        font.family: win.fMono
                        font.pixelSize: 11
                        font.letterSpacing: 1.5
                    }

                    cursorDelegate: Rectangle {
                        width: win.mode === "insert" ? 2 : 0
                        color: Theme.accent
                        visible: win.mode === "insert"
                    }

                    Keys.onPressed: (event) => win.handleKey(event)
                }

                MouseArea {
                    id: searchBoxHover
                    z: 100
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: win.mode === "normal"
                    cursorShape: Qt.IBeamCursor
                    onClicked: {
                        win.mode = "insert"
                        searchInput.forceActiveFocus()
                    }
                }
            }

            Pick {
                anchors.right: parent.right
                label: "live preview"
                opts: ["off", "on"]
                cur: win.live ? 1 : 0
                onPicked: i => win.setLive(i === 1)
            }
        }

        // strip
        DotRing {
            x: stage.width / 2 - width / 2
            y: 850 - height / 2
            width: win.size(0) + 36
            height: width
            n: 60
            dot: 4
            f: win.items.length > 1 ? win.sel / (win.items.length - 1) : 0
        }
        Repeater {
            model: win.items
            delegate: Item {
                id: th
                required property var modelData
                required property int index
                readonly property real d: index - win.pos

                visible: Math.abs(d) < 7.5
                x: stage.width / 2 + win.off(d) - 95
                y: 850 - 95
                width: 190
                height: 190
                scale: win.size(d) / 190
                opacity: 1 - Math.abs(d) * 0.12

                Loader {
                    anchors.fill: parent
                    active: th.visible && !th.modelData.isNone
                    sourceComponent: Art { url: ""; step: 6 }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: win.fade(Theme.bg, th.modelData.isNone ? 1 : 0.55)
                    border.width: 1
                    border.color: win.dim(0.3)
                    Dot {
                        anchors.centerIn: parent
                        text: win.badge(th.modelData)
                        font.pixelSize: text.length <= 3 ? 64 : 40
                    }
                }
                // kept now
                Rectangle {
                    visible: th.modelData.state === win.current
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: th.index === win.sel ? 36 : 22 }
                    width: 10; height: 10; radius: 5
                    color: Theme.accent
                }
                TapHandler {
                    onTapped: {
                        win.mode = "normal"
                        if (th.index === win.sel) win.commit()
                        else win.sel = th.index
                        searchInput.forceActiveFocus()
                    }
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }

        Row {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 56 }
            spacing: 34
            Repeater {
                model: win.mode === "insert"
                    ? ["←→ browse", "↵ apply", "esc normal"]
                    : ["←→ browse", "↵ apply", "p live", "i filter", "esc cancel"]
                Cap { required property string modelData; text: modelData }
            }
        }
    }
}

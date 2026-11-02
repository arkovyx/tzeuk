import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    // ───────────────────────── Config ─────────────────────────
    property bool shown: false                  // visible on spawn
    property bool quitOnClose: false           // true when run via `qs -p`
    property bool useStub: false               // true = stubApps instead of .desktop files
    property var terminal: ["foot", "-e"]      // used for Terminal=true apps
    property string mode: "insert"             // "insert" | "normal"

    readonly property int lines: 10            // visible rows
    readonly property int rowH: 40
    readonly property int winW: 460
    readonly property int pad: 20

    // ───────────────────────── Palette (Nothing) ─────────────────────────
    readonly property color cBlack: "#000000"
    readonly property color cWhite: "#FFFFFF"
    readonly property color cRed: "#D71921"
    function dim(a) { return Qt.rgba(1, 1, 1, a) }
    function pad2(n) { return String(n).padStart(2, "0") }

    // ───────────────────────── Fonts ─────────────────────────
    FontLoader { id: fDotLoader;  source: Qt.resolvedUrl("launcher/fonts/Doto[ROND,wght].ttf") }
    FontLoader { id: fSansLoader; source: Qt.resolvedUrl("launcher/fonts/SpaceGrotesk-Regular.otf") }
    FontLoader { id: fBoldLoader; source: Qt.resolvedUrl("launcher/fonts/SpaceGrotesk-Bold.otf") }
    FontLoader { id: fMonoLoader; source: Qt.resolvedUrl("launcher/fonts/SpaceMono-Regular.ttf") }

    readonly property string fDot:  fDotLoader.name  !== "" ? fDotLoader.name  : "monospace"
    readonly property string fSans: fSansLoader.name !== "" ? fSansLoader.name : "sans-serif"
    readonly property string fBold: fBoldLoader.name !== "" ? fBoldLoader.name : "sans-serif"
    readonly property string fMono: fMonoLoader.name !== "" ? fMonoLoader.name : "monospace"

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // ───────────────────────── Backend ─────────────────────────
    // Run a shell command fully detached.
    function sh(cmd) { Quickshell.execDetached(["setsid", "-f", "sh", "-c", cmd]) }

    function baseName(p) {
        const i = p.lastIndexOf("/")
        return i >= 0 ? p.substring(i + 1) : p
    }

    // Launch a .desktop entry (honours Terminal=true via `terminal`).
    function runEntry(e) {
        let cmd = e.command ? Array.from(e.command) : []
        if (cmd.length === 0) { e.execute(); return }
        if (e.runInTerminal) cmd = terminal.concat(cmd)
        const spec = { command: ["setsid", "-f"].concat(cmd) }
        if (e.workingDirectory) spec.workingDirectory = e.workingDirectory
        Quickshell.execDetached(spec)
    }

    // Executables found in $PATH (fuzzel's list-executables-in-path). Rescanned on open.
    property var pathBins: []
    Process {
        id: pathScan
        running: true
        command: ["sh", "-c",
            "IFS=:; for d in $PATH; do [ -d \"$d\" ] && find -L \"$d\" -maxdepth 1 -mindepth 1 -type f -perm -u+x -printf '%f\\n' 2>/dev/null; done | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: root.pathBins = text.split("\n").filter(s => s.length > 0)
        }
    }

    // Hand-written entries (useStub) / template for custom sources.
    property var stubApps: [
        { kind: "app", name: "Terminal", sub: "foot",    icon: "utilities-terminal",  haystack: "terminal shell",  launch: () => root.sh("foot") },
        { kind: "app", name: "Browser",  sub: "firefox", icon: "firefox",             haystack: "web internet",    launch: () => root.sh("firefox") },
        { kind: "app", name: "Files",    sub: "thunar",  icon: "system-file-manager", haystack: "file manager",    launch: () => root.sh("thunar") }
    ]

    // Default backend: desktop entries first, then PATH executables not already covered.
    function loadApps() {
        if (useStub) return stubApps
        const entries = DesktopEntries.applications.values
        const out = []
        const seen = Object.create(null)

        for (let i = 0; i < entries.length; i++) {
            const e = entries[i]
            if (e.noDisplay) continue
            if (e.command && e.command.length > 0) seen[baseName(e.command[0])] = true
            out.push({
                kind: "app",
                name: e.name,
                sub: e.comment || e.genericName || "",
                icon: e.icon || "",
                haystack: [e.genericName, e.comment, (e.keywords || []).join(" "), e.id].join(" ").toLowerCase(),
                launch: () => root.runEntry(e)
            })
        }
        out.sort((a, b) => a.name.localeCompare(b.name))

        const bins = pathBins
        for (let i = 0; i < bins.length; i++) {
            const b = bins[i]
            if (seen[b]) continue
            out.push({
                kind: "bin", name: b, sub: "", icon: "", haystack: "",
                launch: () => Quickshell.execDetached(["setsid", "-f", b])
            })
        }
        return out
    }

    // ───────────────────────── Search ─────────────────────────
    property string query: ""
    property var allApps: loadApps()
    readonly property var results: filterApps(allApps, query)

    function fuzzy(text, q) {
        let i = 0
        for (let j = 0; j < text.length && i < q.length; j++)
            if (text[j] === q[i]) i++
        return i === q.length
    }

    function scoreApp(app, q) {
        const n = app.name.toLowerCase()
        let s = 0
        if (n === q) s = 1000
        else if (n.startsWith(q)) s = 800
        else if (n.includes(" " + q) || n.includes("-" + q)) s = 600
        else if (n.includes(q)) s = 400
        else if (app.haystack && app.haystack.includes(q)) s = 200
        else if (fuzzy(n, q)) s = 100
        return (s > 0 && app.kind === "bin") ? s - 1 : s     // apps win ties
    }

    function filterApps(apps, q) {
        const t = q.trim()
        if (t === "") return apps.filter(a => a.kind === "app")   // empty prompt: apps only

        const lq = t.toLowerCase()
        const hits = apps
            .map(a => ({ app: a, s: scoreApp(a, lq) }))
            .filter(x => x.s > 0)
            .sort((a, b) => (b.s - a.s)
                         || (a.app.name.length - b.app.name.length)
                         || a.app.name.localeCompare(b.app.name))
            .map(x => x.app)

        // Always offer the typed text as a command.
        hits.push({ kind: "cmd", name: t, sub: "RUN COMMAND", icon: "", haystack: "",
                    launch: () => root.sh(t) })
        return hits
    }

    onQueryChanged: list.currentIndex = 0
    onResultsChanged: list.currentIndex = Math.min(list.currentIndex, Math.max(0, results.length - 1))

    // ───────────────────────── Actions ─────────────────────────
    function close() {
        shown = false
        if (quitOnClose) Qt.quit()
    }

    function reset() {
        mode = "insert"
        input.text = ""
        list.currentIndex = 0
        pathScan.running = true
        input.forceActiveFocus()
    }

    function jump(i) {
        const n = results.length
        if (n === 0) return
        list.currentIndex = Math.max(0, Math.min(n - 1, i))
    }

    function move(d) {
        const n = results.length
        if (n === 0) return
        if (Math.abs(d) === 1) list.currentIndex = (list.currentIndex + d + n) % n   // wrap
        else jump(list.currentIndex + d)                                             // clamp
    }

    function launchCurrent() {
        const app = results[list.currentIndex]
        if (!app) return
        app.launch()
        close()
    }

    function runRaw() {
        const t = query.trim()
        if (t === "") return
        sh(t)
        close()
    }

    // Central key handling for both vim modes.
    function handleKey(event) {
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0
        const shift = (event.modifiers & Qt.ShiftModifier) !== 0
        event.accepted = true

        // Shared by both modes
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (shift) runRaw(); else launchCurrent()
            return
        }
        if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_N || event.key === Qt.Key_J))) { move(1); return }
        if (event.key === Qt.Key_Up   || (ctrl && (event.key === Qt.Key_P || event.key === Qt.Key_K))) { move(-1); return }
        if (event.key === Qt.Key_PageDown) { move(root.lines / 2); return }
        if (event.key === Qt.Key_PageUp)   { move(-root.lines / 2); return }

        if (mode === "insert") {
            if (event.key === Qt.Key_Escape || (ctrl && event.key === Qt.Key_BracketLeft)) { mode = "normal"; return }
            if (event.key === Qt.Key_Tab)     { move(1); return }
            if (event.key === Qt.Key_Backtab) { move(-1); return }
            event.accepted = false              // let TextInput type
            return
        }

        // NORMAL mode: every other key is swallowed
        if (ctrl) {
            if (event.key === Qt.Key_D) move(root.lines / 2)
            else if (event.key === Qt.Key_U) move(-root.lines / 2)
            return
        }
        switch (event.key) {
        case Qt.Key_Escape: close(); break
        case Qt.Key_I:      mode = "insert"; break
        case Qt.Key_J:      move(1); break
        case Qt.Key_K:      move(-1); break
        case Qt.Key_G:      if (shift) jump(results.length - 1); else jump(0); break
        }
    }

    // Paints a dot-matrix strip onto a Canvas.
    function paintDots(canvas, gap, alpha) {
        const ctx = canvas.getContext("2d")
        ctx.reset()
        ctx.fillStyle = "rgba(255,255,255," + alpha + ")"
        for (let y = gap / 2; y < canvas.height; y += gap)
            for (let x = gap / 2; x < canvas.width; x += gap) {
                ctx.beginPath()
                ctx.arc(x, y, 1, 0, Math.PI * 2)
                ctx.fill()
            }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.shown = !root.shown }
        function open(): void { root.shown = true }
        function close(): void { root.shown = false }
    }

    // ───────────────────────── Window ─────────────────────────
    PanelWindow {
        id: win
        visible: root.shown
        implicitWidth: root.winW
        implicitHeight: col.implicitHeight + root.pad * 2
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore            // no anchors => centered

        WlrLayershell.namespace: "tzeuk-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: if (visible) root.reset()

        Rectangle {
            id: card
            anchors.fill: parent
            radius: 28
            color: root.cBlack
            border.color: root.cWhite
            border.width: 1

            ColumnLayout {
                id: col
                x: root.pad
                y: root.pad
                width: card.width - root.pad * 2
                spacing: 12

                // ── Header: dot-matrix clock + LED ──
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: root.cWhite
                        font.family: root.fDot
                        font.weight: Font.Black
                        font.pixelSize: 46
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Qt.formatDateTime(clock.date, "ddd dd MMM").toUpperCase()
                            color: root.dim(0.6)
                            font.family: root.fMono
                            font.pixelSize: 11
                            font.letterSpacing: 1
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 8; height: 8; radius: 4
                            color: root.cRed
                            SequentialAnimation on opacity {
                                running: win.visible
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.2; duration: 800 }
                                NumberAnimation { to: 1.0; duration: 800 }
                            }
                        }
                    }
                }

                Canvas {
                    id: ruleTop
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    onPaint: root.paintDots(ruleTop, 5, 0.45)
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                }

                // ── Search pill ──
                Rectangle {
                    id: bar
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: 24
                    color: root.cBlack
                    border.width: 1
                    border.color: root.mode === "insert" ? root.cWhite : root.dim(0.3)
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Text {
                        id: prompt
                        x: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: ">"
                        color: root.cRed
                        font.family: root.fDot
                        font.weight: Font.Black
                        font.pixelSize: 22
                    }

                    // Mode tag
                    Rectangle {
                        id: tag
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 76; height: 30; radius: 15
                        color: root.mode === "insert" ? "transparent" : root.cWhite
                        border.width: 1
                        border.color: root.mode === "insert" ? root.cRed : root.cWhite

                        Text {
                            anchors.centerIn: parent
                            text: root.mode === "insert" ? "INSERT" : "NORMAL"
                            color: root.mode === "insert" ? root.cRed : root.cBlack
                            font.family: root.fMono
                            font.pixelSize: 10
                            font.letterSpacing: 1
                        }
                    }

                    Item {
                        anchors.left: prompt.right
                        anchors.leftMargin: 12
                        anchors.right: tag.left
                        anchors.rightMargin: 10
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        clip: true

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text.length === 0
                            text: "SEARCH OR RUN"
                            color: root.dim(0.4)
                            font.family: root.fMono
                            font.pixelSize: 13
                            font.letterSpacing: 1.5
                        }

                        TextInput {
                            id: input
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            focus: true
                            readOnly: root.mode === "normal"
                            color: root.cWhite
                            selectionColor: root.cRed
                            selectedTextColor: root.cWhite
                            font.family: root.fSans
                            font.pixelSize: 19
                            inputMethodHints: Qt.ImhNoPredictiveText

                            // Solid red block in INSERT, hollow block in NORMAL.
                            cursorDelegate: Rectangle {
                                width: 9
                                color: root.mode === "insert" ? root.cRed : "transparent"
                                border.width: 1
                                border.color: root.cRed
                            }

                            onTextChanged: root.query = text
                            Component.onCompleted: forceActiveFocus()
                            Keys.onPressed: event => root.handleKey(event)
                        }
                    }
                }

                // ── Results ──
                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.lines * root.rowH
                    clip: true
                    model: root.results
                    currentIndex: 0
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 0
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool current: ListView.isCurrentItem
                        readonly property color fg: current ? root.cBlack : root.cWhite

                        width: list.width
                        height: root.rowH

                        // Selected row = inverted white pill
                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: row.current ? root.cWhite : "transparent"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 18
                            spacing: 12

                            // LED marker
                            Rectangle {
                                Layout.preferredWidth: 6
                                Layout.preferredHeight: 6
                                radius: 3
                                color: root.cRed
                                opacity: row.current ? 1 : 0
                            }

                            // Monochrome icon (letter tile fallback)
                            Item {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24

                                Image {
                                    id: ico
                                    anchors.fill: parent
                                    source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, true) : ""
                                    sourceSize.width: 48
                                    sourceSize.height: 48
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    visible: status === Image.Ready
                                    layer.enabled: status === Image.Ready
                                    layer.effect: MultiEffect { saturation: -1.0 }
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 12
                                    visible: ico.status !== Image.Ready
                                    color: "transparent"
                                    border.width: 1
                                    border.color: row.fg
                                    Text {
                                        anchors.centerIn: parent
                                        text: row.modelData.kind === "cmd" ? ">_" : row.modelData.name.charAt(0).toUpperCase()
                                        color: row.fg
                                        font.family: root.fDot
                                        font.weight: Font.Black
                                        font.pixelSize: row.modelData.kind === "cmd" ? 10 : 13
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.name
                                elide: Text.ElideRight
                                color: row.fg
                                font.family: row.current ? root.fBold : root.fSans
                                font.weight: row.current ? Font.Bold : Font.Normal
                                font.pixelSize: 16
                            }

                            // Kind tag (apps stay clean)
                            Text {
                                visible: row.modelData.kind !== "app"
                                text: row.modelData.kind === "cmd" ? "RUN" : "BIN"
                                color: row.current ? root.dim(0) : root.dim(0.4)
                                Component.onCompleted: color = Qt.binding(() => row.current ? Qt.rgba(0, 0, 0, 0.55) : root.dim(0.4))
                                font.family: root.fMono
                                font.pixelSize: 10
                                font.letterSpacing: 1
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onPositionChanged: list.currentIndex = row.index
                            onClicked: { list.currentIndex = row.index; root.launchCurrent() }
                        }
                    }

                    // Minimal scroll indicator
                    Rectangle {
                        visible: list.visibleArea.heightRatio < 1
                        x: list.width - 2
                        y: list.visibleArea.yPosition * list.height
                        width: 2
                        height: Math.max(16, list.visibleArea.heightRatio * list.height)
                        color: root.dim(0.5)
                    }
                }

                Canvas {
                    id: ruleBottom
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    onPaint: root.paintDots(ruleBottom, 5, 0.45)
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                }

                // ── Footer ──
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18

                    Text {
                        text: root.mode === "insert"
                              ? "ESC NORMAL   ENTER RUN   S-ENTER RAW"
                              : "J/K MOVE   ENTER RUN   I INSERT   ESC QUIT"
                        color: root.dim(0.45)
                        font.family: root.fMono
                        font.pixelSize: 10
                        font.letterSpacing: 1
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.results.length === 0
                              ? "00/00"
                              : root.pad2(list.currentIndex + 1) + "/" + root.pad2(root.results.length)
                        color: root.cRed
                        font.family: root.fDot
                        font.weight: Font.Black
                        font.pixelSize: 16
                    }
                }
            }
        }
    }
}

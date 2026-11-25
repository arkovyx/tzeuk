import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../themes"
import "../glyphs"

// Wallpaper picker: tzeuk functionality (ALL / FOLDERS views, breadcrumb, filter with normal/insert modes,
// thumb cache, awww/swww/hyprpaper apply + tzk-theme, IPC "wallpaper") with the Glyph look: the whole screen is
// the preview (the selected picture assembles as dots in a wave), a strip of dot-circle thumbs at the bottom with a
// progress ring, big Doto counter, look / dot size / light controls.
//
// Keys (normal): ←→ / h l browse · ↵ / space set (enter folder) · i or / filter · tab all/folders · c look (shift+c back)
//                ↑↓ dot size · shift ↑↓ light · g / G first / last · backspace up · esc back
// Keys (insert): type to filter · ←→ browse · ↵ set · esc normal
// Mouse: wheel browses, click a circle selects it, click the selected one sets it.
// Look / dot size / light are saved on apply (cacheDir/glyph-look) and affect the preview.
Scope {
    id: picker
    property bool shown: false
    property string mode: "normal"      // "normal" | "insert"

    WallSettings { id: settings }

    readonly property string fDot:  Theme.fontDoto !== "" ? Theme.fontDoto : "monospace"
    readonly property string fMono: Theme.fontMono !== "" ? Theme.fontMono : "monospace"
    readonly property string fSans: Theme.fontSans !== "" ? Theme.fontSans : "sans-serif"

    function dim(a) { return Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, a) }
    function fade(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function pad2(n) { return String(n).padStart(2, "0") }
    function fileUrl(p) { return p ? "file://" + String(p).split("/").map(encodeURIComponent).join("/") : "" }

    // ── State ──
    property string viewMode: "all"
    property string currentPath: ""
    property string filterQuery: ""
    property var allWallpapers: []
    property var allDirs: [""]
    property var folderCounts: ({})
    property var folderPreview: ({})
    property bool scanning: false

    property int sel: 0                 // selected index in displayedItems
    property string currentWall: ""     // wallpaper that is live now (last applied)
    property int look: 0
    property int pitch: 10
    property int bright: 85
    readonly property var looks: ["dots", "vivid", "mono", "color"]
    readonly property var order: [0, 3, 1, 2]   // look number per pill position

    // ── Derived ──
    readonly property var displayedItems: {
        let items = rebuildItems()
        if (!filterQuery) return items
        const q = filterQuery.toLowerCase()
        return items.filter(it => {
            if (it.type === "folder") return it.name.toLowerCase().indexOf(q) >= 0
            return it.file.toLowerCase().indexOf(q) >= 0
        })
    }
    onDisplayedItemsChanged: clampSel()

    readonly property var breadcrumb: {
        const parts = currentPath === "" ? [] : currentPath.split("/")
        const out = [{ label: "WALLPAPERS", path: "" }]
        let acc = ""
        for (let i = 0; i < parts.length; i++) {
            acc = acc === "" ? parts[i] : acc + "/" + parts[i]
            out.push({ label: parts[i], path: acc })
        }
        return out
    }

    // picture shown in the big preview: the selected wallpaper (or a folder's preview), debounced while browsing
    readonly property string wantPath: {
        const it = displayedItems[sel]
        if (!it) return ""
        if (it.type === "folder") return it.preview ? it.preview.path : ""
        return it.path
    }
    property string viewPath: ""
    onWantPathChanged: settle.restart()
    Timer { id: settle; interval: 160; onTriggered: picker.viewPath = picker.wantPath }

    readonly property string selName: {
        const it = displayedItems[sel]
        if (!it) return "nothing"
        if (it.type === "folder") return it.name
        return it.file.replace(/\.[^.]+$/, "")
    }

    function clampSel() {
        const n = displayedItems.length
        sel = n === 0 ? 0 : Math.max(0, Math.min(n - 1, sel))
    }
    function go(d) {
        const n = displayedItems.length
        if (n === 0) return
        sel = Math.max(0, Math.min(n - 1, sel + d))
    }
    function cycleLook(dir) {
        const i = order.indexOf(look)
        look = order[(i + dir + order.length) % order.length]
    }

    function rebuildItems() {
        if (viewMode === "all") return allWallpapers
        const out = []
        const prefix = currentPath === "" ? "" : currentPath + "/"
        const folderSet = Object.create(null)
        for (let i = 0; i < allDirs.length; i++) {
            const d = allDirs[i]
            if (d === "" || d === currentPath) continue
            if (!d.startsWith(prefix)) continue
            const rest = d.substring(prefix.length)
            if (rest.indexOf("/") >= 0) continue
            if (folderSet[rest]) continue
            folderSet[rest] = true
            out.push({
                type: "folder",
                name: rest,
                path: d,
                count: folderCounts[d] || 0,
                preview: folderPreview[d] || null
            })
        }
        out.sort((a, b) => a.name.localeCompare(b.name))
        for (let i = 0; i < allWallpapers.length; i++) {
            const w = allWallpapers[i]
            if (w.dir === currentPath) out.push(w)
        }
        return out
    }

    // ── Scan ──
    Process {
        id: scanProcess
        stdout: StdioCollector {
            id: scanOut
            onStreamFinished: picker.parseScan(scanOut.text)
        }
    }

    function scan() {
        scanning = true
        const extExpr = settings.imageExtensions.map(e => "-iname '*." + e + "'").join(" -o ")
        const script = `
ROOT='${settings.wallpapersRoot}'
CACHE='${settings.cacheDir}'
[ -f "$CACHE/last_wallpaper" ] && printf 'C|%s\\n' "$(cat "$CACHE/last_wallpaper")"
[ -f "$CACHE/glyph-look" ] && printf 'P|%s\\n' "$(cat "$CACHE/glyph-look")"
[ -d "$ROOT" ] || exit 0
find "$ROOT" -type d -printf 'D|%P\\n' 2>/dev/null
find "$ROOT" -type f \\( ${extExpr} \\) -printf 'F|%P\\n' 2>/dev/null
`
        scanProcess.command = ["bash", "-c", script]
        scanProcess.running = true
    }

    function parseScan(text) {
        const files = []
        const dirSet = Object.create(null)
        dirSet[""] = true
        const exts = {}
        for (let i = 0; i < settings.imageExtensions.length; i++)
            exts[settings.imageExtensions[i].toLowerCase()] = true

        const lines = String(text || "").split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            if (!line) continue
            const sep = line.indexOf("|")
            if (sep <= 0) continue
            const kind = line.substring(0, sep)
            const rel = line.substring(sep + 1)
            if (!rel) continue
            if (kind === "C") {
                currentWall = rel.trim()
            } else if (kind === "P") {
                const p = rel.trim().split(/\s+/).map(Number)
                if (p.length === 3 && p.every(x => !isNaN(x))) {
                    if (order.indexOf(p[0]) >= 0) look = p[0]
                    pitch = Math.max(4, Math.min(32, p[1]))
                    bright = Math.max(10, Math.min(100, p[2]))
                }
            } else if (kind === "D") {
                dirSet[rel] = true
            } else if (kind === "F") {
                const slash = rel.lastIndexOf("/")
                const file = slash < 0 ? rel : rel.substring(slash + 1)
                const dir = slash < 0 ? "" : rel.substring(0, slash)
                const dot = file.lastIndexOf(".")
                if (dot < 0) continue
                const ext = file.substring(dot + 1).toLowerCase()
                if (!exts[ext]) continue
                files.push({
                    type: "wallpaper",
                    dir: dir,
                    file: file,
                    relative: rel,
                    path: settings.wallpapersRoot + "/" + rel,
                    thumb: settings.thumbDir + "/" + rel.split("/").join("__")
                })
            }
        }
        files.sort((a, b) => a.relative.localeCompare(b.relative))

        const counts = Object.create(null)
        const preview = Object.create(null)
        for (let i = 0; i < files.length; i++) {
            const f = files[i]
            const parts = f.relative.split("/")
            for (let j = 0; j < parts.length - 1; j++) {
                const folderPath = parts.slice(0, j + 1).join("/")
                counts[folderPath] = (counts[folderPath] || 0) + 1
                if (!preview[folderPath]) preview[folderPath] = f
            }
        }

        allWallpapers = files
        allDirs = Object.keys(dirSet)
        folderCounts = counts
        folderPreview = preview
        scanning = false

        // start on the wallpaper that is live now
        if (viewMode === "all" && filterQuery === "") {
            const idx = files.findIndex(f => f.path === currentWall)
            sel = idx >= 0 ? idx : 0
        }
        syncThumbs()
    }

    Process { id: thumbProcess }

    function syncThumbs() {
        const extExpr = settings.imageExtensions.map(e => "-iname '*." + e + "'").join(" -o ")
        const script = `
THUMB_DIR='${settings.thumbDir}'
ROOT='${settings.wallpapersRoot}'
mkdir -p "$THUMB_DIR"
CMD=""
if command -v magick >/dev/null 2>&1; then CMD="magick"
elif command -v convert >/dev/null 2>&1; then CMD="convert"
else exit 0
fi
find "$ROOT" -type f \\( ${extExpr} \\) -print0 2>/dev/null | while IFS= read -r -d '' src; do
    rel="\${src#$ROOT/}"
    dest="$THUMB_DIR/\${rel//\\//__}"
    if [ -f "$dest" ] && [ "$dest" -nt "$src" ]; then continue; fi
    $CMD "$src" -auto-orient -thumbnail '800x500>' -quality 82 "$dest" 2>/dev/null || true
done
`
        thumbProcess.command = ["bash", "-c", script]
        thumbProcess.running = true
    }

    // ── Navigation ──
    function resetNav() {
        filterQuery = ""
        searchInput.text = ""
        sel = 0
        Qt.callLater(() => searchInput.forceActiveFocus())
    }

    function enterFolder(path) {
        currentPath = path
        viewMode = "folders"
        resetNav()
    }

    function goUp() {
        if (currentPath === "") { viewMode = "all"; resetNav(); return }
        const parts = currentPath.split("/")
        parts.pop()
        currentPath = parts.join("/")
        resetNav()
    }

    function gotoPath(path) {
        currentPath = path
        viewMode = "folders"
        resetNav()
    }

    function toggleMode() {
        viewMode = viewMode === "all" ? "folders" : "all"
        currentPath = ""
        resetNav()
    }

    function activateCurrent() {
        const items = displayedItems
        if (sel < 0 || sel >= items.length) return
        const item = items[sel]
        if (item.type === "folder") enterFolder(item.path)
        else applyWallpaper(item)
    }

    function handleEscape() {
        if (filterQuery !== "") {
            filterQuery = ""
            searchInput.text = ""
            return
        }
        if (viewMode === "folders" && currentPath !== "") { goUp(); return }
        if (viewMode === "folders") { viewMode = "all"; resetNav(); return }
        shown = false
    }

    // ── Apply ──
    function applyWallpaper(item) {
        if (!item || item.type !== "wallpaper") return

        const script = `
WALL="$1"
CACHE_DIR="$2"
DUR="$3"
FPS="$4"
BACKEND_PREF="$5"
TYPES_STR="$6"

mkdir -p "$CACHE_DIR"
printf '%s' "$WALL" > "$CACHE_DIR/last_wallpaper"

LOG="$CACHE_DIR/apply.log"
if [ -f "$LOG" ] && [ "$(stat -c%s "$LOG" 2>/dev/null || echo 0)" -gt 1000000 ]; then
    : > "$LOG"
fi
exec >> "$LOG" 2>&1
echo ""
echo "=== $(date '+%F %T') ==="
echo "WALL=$WALL"
echo "TYPES=$TYPES_STR"

BACKEND="$BACKEND_PREF"
if [ "$BACKEND" = "auto" ] || [ -z "$BACKEND" ]; then
    if command -v awww >/dev/null 2>&1; then BACKEND="awww"
    elif command -v swww >/dev/null 2>&1; then BACKEND="swww"
    elif command -v hyprctl >/dev/null 2>&1; then BACKEND="hyprpaper"
    else BACKEND="none"
    fi
fi
echo "BACKEND=$BACKEND"

pick_transition() {
    local -a arr
    read -r -a arr <<< "$TYPES_STR"
    local n=\${#arr[@]}
    if [ "$n" -eq 0 ]; then echo "fade"; return; fi
    local idx=$((RANDOM % n))
    echo "\${arr[$idx]}"
}

case "$BACKEND" in
    awww)
        pgrep -x awww-daemon >/dev/null 2>&1 || { awww-daemon >/dev/null 2>&1 & sleep 0.6; }
        T=$(pick_transition)
        echo "TRANSITION=$T"
        if ! awww img --transition-type "$T" --transition-duration "$DUR" --transition-fps "$FPS" "$WALL"; then
            echo "awww transition failed, trying plain"
            awww img "$WALL" || echo "awww FAILED"
        fi
        ;;
    swww)
        pgrep -x swww-daemon >/dev/null 2>&1 || { swww-daemon >/dev/null 2>&1 & sleep 0.6; }
        T=$(pick_transition)
        echo "TRANSITION=$T"
        if ! swww img --transition-type "$T" --transition-duration "$DUR" --transition-fps "$FPS" "$WALL"; then
            echo "swww transition failed, trying plain"
            swww img "$WALL" || echo "swww FAILED"
        fi
        ;;
    hyprpaper)
        pgrep -x hyprpaper >/dev/null 2>&1 || echo "WARN: hyprpaper not running"
        if hyprctl hyprpaper wallpaper ",$WALL"; then
            echo "hyprpaper OK (direct)"
        else
            echo "hyprpaper direct failed, preloading + per-monitor"
            hyprctl hyprpaper preload "$WALL" || true
            sleep 0.15
            MONS=$(hyprctl monitors 2>/dev/null | awk '/^Monitor /{print $2}')
            if [ -n "$MONS" ]; then
                for mon in $MONS; do
                    hyprctl hyprpaper wallpaper "$mon,$WALL" || true
                done
            else
                hyprctl hyprpaper wallpaper ",$WALL" || true
            fi
        fi
        ;;
    *)
        echo "No wallpaper backend found"
        exit 1
        ;;
esac

tzk-theme "$WALL" 2>/dev/null || echo "tzk-theme FAILED"
`
        Quickshell.execDetached([
            "bash", "-c", script, "apply",
            item.path,
            settings.cacheDir,
            String(settings.transitionDuration),
            String(settings.transitionFps),
            settings.wallpaperBackend,
            settings.setAnimations.join(" ")
        ])
        Quickshell.execDetached([
            "bash", "-c", 'printf "%s %s %s" "$1" "$2" "$3" > "$4/glyph-look"', "save",
            String(look), String(pitch), String(bright), settings.cacheDir
        ])
        currentWall = item.path
        shown = false
    }

    // ── Lifecycle ──
    onShownChanged: {
        if (shown) {
            mode = "normal"
            viewMode = "all"
            currentPath = ""
            filterQuery = ""
            searchInput.text = ""
            sel = 0
            viewPath = ""
            scan()
            Qt.callLater(() => searchInput.forceActiveFocus())
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["bash", "-c",
            "mkdir -p '" + settings.cacheDir + "' '" + settings.thumbDir + "'"])
    }

    IpcHandler {
        target: "wallpaper"
        function toggle() { picker.shown = !picker.shown }
        function open()   { picker.shown = true }
        function close()  { picker.shown = false }
    }

    // ── Keyboard ──
    function handleKey(event) {
        const shift = (event.modifiers & Qt.ShiftModifier) !== 0
        const up = event.key === Qt.Key_Up, down = event.key === Qt.Key_Down
        event.accepted = true

        if (event.key === Qt.Key_Left) { go(-1); return }
        if (event.key === Qt.Key_Right) { go(1); return }
        if (event.key === Qt.Key_PageUp) { go(-5); return }
        if (event.key === Qt.Key_PageDown) { go(5); return }
        if (event.key === Qt.Key_Home) { sel = 0; return }
        if (event.key === Qt.Key_End) { sel = Math.max(0, displayedItems.length - 1); return }
        if (up || down) {
            if (shift) bright = Math.max(10, Math.min(100, bright + (up ? 5 : -5)))
            else pitch = Math.max(4, Math.min(32, pitch + (up ? 1 : -1)))
            return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { activateCurrent(); return }
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) { toggleMode(); return }

        if (mode === "insert") {
            if (event.key === Qt.Key_Escape) { mode = "normal"; return }
            event.accepted = false
            return
        }

        switch (event.key) {
        case Qt.Key_Escape:
            handleEscape()
            break
        case Qt.Key_I:
        case Qt.Key_Slash:
            mode = "insert"
            searchInput.forceActiveFocus()
            break
        case Qt.Key_H:
            go(-1)
            break
        case Qt.Key_L:
            go(1)
            break
        case Qt.Key_G:
            sel = shift ? Math.max(0, displayedItems.length - 1) : 0
            break
        case Qt.Key_C:
            cycleLook(shift ? -1 : 1)
            break
        case Qt.Key_Space:
            activateCurrent()
            break
        case Qt.Key_Backspace:
            if (viewMode === "folders") goUp()
            break
        }
    }

    // ── UI ──
    PanelWindow {
        id: win

        property real t: picker.shown ? 1 : 0
        Behavior on t { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] } }

        // the strip glides with one animation: pos follows sel
        property real pos: picker.sel
        Behavior on pos { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] } }

        // circle at distance d: selected 190, neighbours 128, then 12 less each, min 64; linear in between
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
        WlrLayershell.namespace: "tzeuk-wallpicker"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: picker.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // 1920x1080 design canvas scaled to the screen
        Item {
            id: stage
            readonly property real u: win.height / 1080
            width: win.width / u
            height: win.height / u
            scale: u
            transformOrigin: Item.TopLeft
            opacity: win.t

            Rectangle { anchors.fill: parent; color: Theme.bg }

            Loader {
                id: prev
                anchors.fill: parent
                active: win.visible
                sourceComponent: Wall {
                    path: picker.viewPath
                    look: picker.look
                    pitch: picker.pitch
                    bright: picker.bright / 100
                    origin: Qt.point(width / 2, 850)
                }
            }

            // wheel browses; click on empty space puts focus back on the filter input
            MouseArea {
                anchors.fill: parent
                property real acc: 0
                onClicked: searchInput.forceActiveFocus()
                onWheel: w => {
                    acc += w.angleDelta.y || w.angleDelta.x
                    while (Math.abs(acc) >= 120) {
                        picker.go(acc > 0 ? -1 : 1)
                        acc -= Math.sign(acc) * 120
                    }
                }
            }

            // labels must stay readable on top of the picture
            Rectangle {
                width: parent.width
                height: 380
                gradient: Gradient {
                    GradientStop { position: 0; color: picker.fade(Theme.bg, 0.85) }
                    GradientStop { position: 1; color: picker.fade(Theme.bg, 0) }
                }
            }
            Rectangle {
                y: parent.height - height
                width: parent.width
                height: 460
                gradient: Gradient {
                    GradientStop { position: 0; color: picker.fade(Theme.bg, 0) }
                    GradientStop { position: 1; color: picker.fade(Theme.bg, 0.9) }
                }
            }

            // counter + name + breadcrumb
            Column {
                x: 150 - 30 * (1 - win.t)
                y: 110

                Cap { text: "wallpaper · " + picker.allWallpapers.length + " in " + settings.wallpapersRoot.replace(Quickshell.env("HOME"), "~") }
                Row {
                    topPadding: 18
                    spacing: 10
                    Dot {
                        id: idx
                        text: picker.pad2(picker.displayedItems.length === 0 ? 0 : picker.sel + 1)
                        font.pixelSize: 150
                    }
                    Dot {
                        anchors.baseline: idx.baseline
                        text: "/" + picker.pad2(picker.displayedItems.length)
                        font.pixelSize: 54
                        color: picker.dim(0.35)
                    }
                }
                Cap {
                    topPadding: 22
                    width: 700
                    elide: Text.ElideRight
                    text: picker.scanning && picker.displayedItems.length === 0 ? "scanning…"
                        : picker.displayedItems.length === 0 ? (picker.filterQuery !== "" ? "no matches" : "empty")
                        : picker.selName
                    px: 14
                    color: Theme.fg
                }
                Row {
                    visible: picker.viewMode === "folders"
                    topPadding: 14
                    spacing: 8
                    Repeater {
                        model: picker.breadcrumb
                        delegate: Row {
                            id: crumb
                            spacing: 8
                            readonly property bool isLast: index === picker.breadcrumb.length - 1
                            Cap {
                                text: modelData.label
                                px: 11
                                color: crumb.isLast || crumbHover.hovered ? Theme.fg : picker.dim(0.5)
                                HoverHandler { id: crumbHover; enabled: !crumb.isLast; cursorShape: Qt.PointingHandCursor }
                                TapHandler { enabled: !crumb.isLast; onTapped: picker.gotoPath(modelData.path) }
                            }
                            Cap { visible: !crumb.isLast; text: "/"; px: 11; color: picker.dim(0.3) }
                        }
                    }
                }
            }

            // filter, view, look, dials
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
                    border.color: picker.mode === "insert" ? Theme.fg
                        : (searchBoxHover.containsMouse ? picker.dim(0.55) : picker.dim(0.25))
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Text {
                        id: prompt
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        text: "/"
                        color: Theme.accent
                        font.family: picker.fDot
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
                        color: picker.mode === "insert"
                            ? (modeBadgeHover.containsMouse ? picker.fade(Theme.accent, 0.15) : "transparent")
                            : Theme.fg
                        border.width: picker.mode === "insert" ? 1 : 0
                        border.color: Theme.accent
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: picker.mode === "insert" ? "INSERT" : "NORMAL"
                            color: picker.mode === "insert" ? Theme.accent : Theme.bg
                            font.family: picker.fMono
                            font.pixelSize: 10
                            font.letterSpacing: 1
                        }
                        MouseArea {
                            id: modeBadgeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                picker.mode = picker.mode === "insert" ? "normal" : "insert"
                                if (picker.mode === "insert") searchInput.forceActiveFocus()
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
                        font.family: picker.fSans
                        font.pixelSize: 15
                        clip: true
                        readOnly: picker.mode === "normal"
                        inputMethodHints: Qt.ImhNoPredictiveText

                        onTextChanged: {
                            picker.filterQuery = text.toLowerCase()
                            picker.sel = 0
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchInput.text.length === 0
                            text: "FILTER BY NAME..."
                            color: picker.dim(0.4)
                            font.family: picker.fMono
                            font.pixelSize: 11
                            font.letterSpacing: 1.5
                        }

                        cursorDelegate: Rectangle {
                            width: picker.mode === "insert" ? 2 : 0
                            color: Theme.accent
                            visible: picker.mode === "insert"
                        }

                        Keys.onPressed: (event) => picker.handleKey(event)
                    }

                    MouseArea {
                        id: searchBoxHover
                        z: 100
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: picker.mode === "normal"
                        cursorShape: Qt.IBeamCursor
                        onClicked: {
                            picker.mode = "insert"
                            searchInput.forceActiveFocus()
                        }
                    }
                }

                Pick {
                    anchors.right: parent.right
                    label: "view"
                    opts: ["all", "folders"]
                    cur: picker.viewMode === "all" ? 0 : 1
                    onPicked: i => { if ((i === 1) !== (picker.viewMode === "folders")) picker.toggleMode() }
                }
                Pick {
                    anchors.right: parent.right
                    label: "look"
                    opts: picker.looks
                    cur: picker.order.indexOf(picker.look)
                    onPicked: i => picker.look = picker.order[i]
                }
                Row {
                    anchors.right: parent.right
                    spacing: 36
                    Dial { size: 120; label: "dot · px"; from: 4; to: 32; value: picker.pitch; onMoved: v => picker.pitch = v }
                    Dial { size: 120; label: "light · %"; from: 10; to: 100; step: 5; value: picker.bright; onMoved: v => picker.bright = v }
                }
            }

            // strip: the selected circle is always in the centre, the ring stays put, circles slide under it
            DotRing {
                x: stage.width / 2 - width / 2
                y: 850 - height / 2
                width: win.size(0) + 36
                height: width
                n: 60
                dot: 4
                f: picker.displayedItems.length > 1 ? picker.sel / (picker.displayedItems.length - 1) : 0
            }
            Repeater {
                model: picker.displayedItems
                delegate: Item {
                    id: th
                    required property var modelData
                    required property int index
                    readonly property bool isFolder: modelData.type === "folder"
                    readonly property var shot: isFolder ? modelData.preview : modelData
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
                        active: th.visible && !!th.shot
                        sourceComponent: Art {
                            url: picker.fileUrl(th.shot.thumb)
                            fallback: picker.fileUrl(th.shot.path)
                            step: 6
                        }
                    }
                    // folder: dimmed circle with the item count; also covers folders without any picture
                    Rectangle {
                        visible: th.isFolder
                        anchors.fill: parent
                        radius: width / 2
                        color: picker.fade(Theme.bg, th.shot ? 0.55 : 1)
                        border.width: 1
                        border.color: picker.dim(0.3)
                        Column {
                            anchors.centerIn: parent
                            spacing: 6
                            Dot { anchors.horizontalCenter: parent.horizontalCenter; text: picker.pad2(th.modelData.count || 0); font.pixelSize: 44 }
                            Cap { anchors.horizontalCenter: parent.horizontalCenter; text: (th.modelData.count === 1 ? "item" : "items"); px: 11 }
                        }
                    }
                    // live now
                    Rectangle {
                        visible: !th.isFolder && th.modelData.path === picker.currentWall
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: th.index === picker.sel ? 36 : 22 }
                        width: 10; height: 10; radius: 5
                        color: Theme.accent
                    }
                    TapHandler {
                        onTapped: {
                            picker.mode = "normal"
                            if (th.index === picker.sel) picker.activateCurrent()
                            else picker.sel = th.index
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
                    model: picker.mode === "insert"
                        ? ["←→ browse", "↵ set", "esc normal"]
                        : ["←→ browse", "↵ set", "i filter", "tab view", "c look", "↑↓ dot size", "shift ↑↓ light", "esc back"]
                    Cap { required property string modelData; text: modelData }
                }
            }
        }
    }
}
